#include <pebble.h>

#define KEY_BUTTON_SELECT 9

// StreetPainter Dictionary Protocol Keys
#define KEY_GAME_MODE 0
#define KEY_PLAYER_ID 1
#define KEY_ITEM_ID 2
#define KEY_WATCH_MOVE 3

// StreetPainter Dictionary Protocol Values
// #define VAL_GAME_MODE_

static Window *window;
static Layer *s_canvas_layer;
static GDrawCommandImage *s_command_image;
static TextLayer *bottom_text_layer;
static TextLayer *player_text_layer;
static TextLayer *player_bg_layer;

// static TextLayer *text_layer;
// static TextLayer *s_output_layer;

static int current_mode = 0;
static int player_id = -1;

// Gs of force (change until accurate sensor reading)
const int X_MAX_THRESHOLD = 1200;
const int Z_MAX_THRESHOLD = 800;
const int X_AVG_THRESHOLD = 500;
const int Z_AVG_THRESHOLD = 500;
const int Z_OFFSET    = 1000;  // Offset gravity on watch

// Define directions
#define DIRECTION_NONE -1
#define DIRECTION_UP 0
#define DIRECTION_DOWN 1
#define DIRECTION_LEFT 2
#define DIRECTION_RIGHT 3

static void update_proc(Layer *layer, GContext *ctx) {
  // Place image in the center of the Window 
  GSize img_size = gdraw_command_image_get_bounds_size(s_command_image);
  GPoint origin = GPoint(72 - (img_size.w / 2), 84 - (img_size.h / 2));
  
  // If the image was loaded successfully...
  if (s_command_image) {
    // Draw it
    gdraw_command_image_draw(ctx, s_command_image, origin);
  }
}

static void canvas_set_image(int resource_id) {
  if (s_command_image) {
    gdraw_command_image_destroy(s_command_image);
  }
  s_command_image = gdraw_command_image_create_with_resource(resource_id);
  if (!s_command_image) {
    printf("ERROR: Unable to load image resource %i", resource_id);
    return;
  }
  layer_mark_dirty(s_canvas_layer);
}

static void send(int key, int value) {
  // Create dictionary
  DictionaryIterator *iter;
  app_message_outbox_begin(&iter);

  // Add value to send
  dict_write_int(iter, key, &value, sizeof(int), true);
  dict_write_int(iter, KEY_PLAYER_ID, &player_id, sizeof(int), true);

  // Send dictionary
  app_message_outbox_send();
}


static void handle_incoming_data(int key, int val) {
  switch(key) {
    case KEY_GAME_MODE:
      break;
    case KEY_PLAYER_ID:
      if (val != -1) {
        player_id = val;
        static char s_buffer[32];
        snprintf(s_buffer, sizeof(s_buffer), "Player %d", player_id);
        // text_layer_set_text(text_layer, s_buffer);
      } else {
        APP_LOG(APP_LOG_LEVEL_WARNING, "Invalid player id sent.");
      }
      break;
    default:
      APP_LOG(APP_LOG_LEVEL_WARNING, "Tuple with key %d is not defined on the Street Painter app", (int)key);
  }
}

static int determine_accel_direction(AccelData *data, uint32_t num_samples) {
  if ((int)num_samples > 0) {
    int avgX = 0; int avgY = 0; int avgZ = 0;
    int maxX = abs(data[0].x);
    int maxY = abs(data[0].y);
    int maxZ = abs(data[0].z);
    for(int i = 0; i < (int)num_samples; i++) {
      avgX += data[i].x; avgY += data[i].y; avgZ += data[i].z;
      maxX = (abs(data[i].x) > maxX) ? abs(data[i].x) : maxX;
      maxY = (abs(data[i].y) > maxY) ? abs(data[i].y) : maxY;
      maxZ = (abs(data[i].z) > maxZ) ? abs(data[i].z) : maxZ;
      // if data[i]
    }
    // Get averages
    avgX = avgX / (int)num_samples;
    avgY = avgY / (int)num_samples;
    avgZ = (avgZ / (int)num_samples) + Z_OFFSET;
    maxZ = maxZ - Z_OFFSET;

    // APP_LOG(APP_LOG_LEVEL_DEBUG, "avg: %d, %d, %d", avgX, avgY, avgZ);
    // APP_LOG(APP_LOG_LEVEL_DEBUG, "abs max: %d, %d, %d", maxX, maxY, maxZ);


    // if ((abs(avgX) > X_MAX_THRESHOLD) || (abs(maxX) > X_MAX_THRESHOLD)) {
    // if ((maxX > X_MAX_THRESHOLD) && (abs(avgX) > X_AVG_THRESHOLD) && (abs(avgX) > abs(avgZ))) {
    //   return (avgX < 0) ? DIRECTION_LEFT : DIRECTION_RIGHT;
    //   // return (avgX < 0) ? DIRECTION_RIGHT : DIRECTION_LEFT;
    // // } else if ((abs(avgZ > Z_MAX_THRESHOLD)) || (abs(maxZ) > Z_MAX_THRESHOLD)) {
    // } else if ((maxZ > Z_MAX_THRESHOLD) && (abs(avgZ) > Z_AVG_THRESHOLD) && (abs(avgZ) >= abs(avgX))) {
    //   return (avgZ < 0) ? DIRECTION_DOWN : DIRECTION_UP;
    // }

    if ((maxZ > Z_MAX_THRESHOLD) && (abs(avgZ) > Z_AVG_THRESHOLD) && (abs(avgZ) >= abs(avgX))) {
      return (avgZ < 0) ? DIRECTION_DOWN : DIRECTION_UP;
      // return (avgX < 0) ? DIRECTION_RIGHT : DIRECTION_LEFT;
    // } else if ((abs(avgZ > Z_MAX_THRESHOLD)) || (abs(maxZ) > Z_MAX_THRESHOLD)) {
    } else if ((maxX > X_MAX_THRESHOLD) && (abs(avgX) > X_AVG_THRESHOLD) && (abs(avgX) > abs(avgZ)))  {
      return (avgX < 0) ? DIRECTION_LEFT : DIRECTION_RIGHT;
    }
  }

  return DIRECTION_NONE;
}

static char * direction_string_for_enum(int direction) {
  switch (direction) {
    case DIRECTION_LEFT:
      return "LEFT";
      break;
    case DIRECTION_RIGHT:
      return "RIGHT";
      break;
    case DIRECTION_UP:
      return "UP";
      break;
    case DIRECTION_DOWN:
      return "DOWN";
      break;
    default:
      return "NONE";
  }
}

static void accelerometer_data_handler(AccelData *data, uint32_t num_samples) {
  // Long lived buffer
  static char s_buffer[128];

  // Compose string of all data
  snprintf(s_buffer, sizeof(s_buffer),
    "N X,Y,Z\n0 %d,%d,%d\n1 %d,%d,%d\n2 %d,%d,%d",
    data[0].x, data[0].y, data[0].z,
    data[1].x, data[1].y, data[1].z,
    data[2].x, data[2].y, data[2].z
  );

  int direction = determine_accel_direction(data, num_samples);

  // APP_LOG(APP_LOG_LEVEL_DEBUG, "direction %d", direction);


  //Show the data
  // text_layer_set_text(s_output_layer, s_buffer);

  // static char* direction_text;
  // switch (direction) {
  //   case DIRECTION_LEFT:
  //     direction_text = "LEFT";
  //     break;
  //   case DIRECTION_RIGHT:
  //     direction_text = "RIGHT";
  //     break;
  //   case DIRECTION_UP:
  //     direction_text = "UP";
  //     break;
  //   case DIRECTION_DOWN:
  //     direction_text = "DOWN";
  //     break;
  //   case DIRECTION_NONE:
  //     direction_text = "NONE";
  //     break;
  //   default:
  //     direction_text = "NONE";
  // }

  if (direction != DIRECTION_NONE) {
    send(KEY_WATCH_MOVE, direction);
    // text_layer_set_text(s_output_layer, direction_text);
  }
}

static void accel_subscribe() {
  // Subscribe to the accelerometer data service
  int num_samples = 3;
  accel_data_service_subscribe(num_samples, accelerometer_data_handler);

  // Choose update rate
  accel_service_set_sampling_rate(ACCEL_SAMPLING_10HZ);
}

static void accel_unsubscribe() {
  accel_data_service_unsubscribe();
}


static void inbox_received_callback(DictionaryIterator *iterator, void *context) {
  APP_LOG(APP_LOG_LEVEL_INFO, "Inbox message received!");

  Tuple *t = dict_read_first(iterator);

  while(t != NULL) {
    APP_LOG(APP_LOG_LEVEL_DEBUG, "Tuple %d: %d", (int)t->key, (int)t->value->int32);
    handle_incoming_data(t->key, t->value->int32);
    t = dict_read_next(iterator);
  }
}

static void inbox_dropped_callback(AppMessageResult reason, void *context) {
  APP_LOG(APP_LOG_LEVEL_WARNING, "Inbox message dropped!");
}

static void outbox_failed_callback(DictionaryIterator *iterator, AppMessageResult reason, void *context) {
  APP_LOG(APP_LOG_LEVEL_ERROR, "Outbox send failed! Reason: %d", (int)reason);
}

static void outbox_sent_callback(DictionaryIterator *iterator, void *context) {
  APP_LOG(APP_LOG_LEVEL_INFO, "Outbox send success!");
}

static void select_click_handler(ClickRecognizerRef recognizer, void *context) {
  APP_LOG(APP_LOG_LEVEL_DEBUG, "Select handler");

  send(KEY_PLAYER_ID, player_id);
}

static void up_click_handler(ClickRecognizerRef recognizer, void *context) {
  accel_subscribe();
  // text_layer_set_text(text_layer, "Up");
}

static void down_click_handler(ClickRecognizerRef recognizer, void *context) {
  accel_unsubscribe();
}

static void click_config_provider(void *context) {
  window_single_click_subscribe(BUTTON_ID_SELECT, select_click_handler);
  window_single_click_subscribe(BUTTON_ID_UP, up_click_handler);
  window_single_click_subscribe(BUTTON_ID_DOWN, down_click_handler);
}

// Drawing stuff!
static void resetScreen() {
  // window_set_background_color
  window_set_background_color(window, GColorFromRGB(255, 255, 255));
  text_layer_set_text(bottom_text_layer, "Error!");
  text_layer_set_text_color(bottom_text_layer, GColorFromRGB(255, 0, 0));
  
  // SETS SPECIFIED SVG ICON
  canvas_set_image(RESOURCE_ID_ERROR_ICON);
  
  text_layer_set_text(player_text_layer, "Player 1");
}

static void window_load(Window *window) {
  Layer *window_layer = window_get_root_layer(window);
  GRect bounds = layer_get_bounds(window_layer);

  s_canvas_layer = layer_create(bounds);
  layer_set_update_proc(s_canvas_layer, update_proc);
  layer_add_child(window_layer, s_canvas_layer);
  
  // Sets text layer point on screen and container size
  bottom_text_layer = text_layer_create((GRect) { .origin = { 0, 128 }, .size = { bounds.size.w, 30 } });
  // Sets text layer left/right/center
  text_layer_set_text_alignment(bottom_text_layer, GTextAlignmentCenter);
  text_layer_set_font(bottom_text_layer, fonts_get_system_font(FONT_KEY_GOTHIC_24_BOLD));
  layer_add_child(window_layer, text_layer_get_layer(bottom_text_layer));
  // Sets clear BG color behind text
  text_layer_set_background_color(bottom_text_layer, GColorClear);

  // Sets header bg color
  player_bg_layer = text_layer_create((GRect) { .origin = {0, 0}, .size = {bounds.size.w, 25} });
  text_layer_set_background_color(player_bg_layer, GColorWhite);
  layer_add_child(window_layer, text_layer_get_layer(player_bg_layer));

  player_text_layer = text_layer_create((GRect) { .origin = { 6, 0 }, .size = { bounds.size.w, 23 } });
  text_layer_set_text_alignment(player_text_layer, GTextAlignmentLeft);
  text_layer_set_font(player_text_layer, fonts_get_system_font(FONT_KEY_GOTHIC_18_BOLD));
  layer_add_child(window_layer, text_layer_get_layer(player_text_layer));
  text_layer_set_background_color(player_text_layer, GColorClear);
  text_layer_set_text_color(player_text_layer, GColorBlack);
  // text_layer_set_text_alignment(player_text_layer, GTextAlignmentCenter);
  // text_layer_set_font(player_text_layer, fonts_get_system_font(FONT_KEY_GOTHIC_24));
  // TODO add background color to player layer
  // layer_add_child(window_layer, text_layer_get_layer(player_text_layer));

  resetScreen();

  // debug
  // text_layer = text_layer_create((GRect) { .origin = { 0, 72 }, .size = { bounds.size.w, 20 } });
  // text_layer_set_text(text_layer, "Press a button");
  // text_layer_set_text_alignment(text_layer, GTextAlignmentCenter);
  // layer_add_child(window_layer, text_layer_get_layer(text_layer));
  //
  //
  // // TEMP Create debug output TextLayer for accelerometer
  // s_output_layer = text_layer_create(GRect(5, 0, bounds.size.w - 10, bounds.size.h));
  // text_layer_set_font(s_output_layer, fonts_get_system_font(FONT_KEY_GOTHIC_24));
  // text_layer_set_text(s_output_layer, "No data yet.");
  // text_layer_set_overflow_mode(s_output_layer, GTextOverflowModeWordWrap);
  // layer_add_child(window_layer, text_layer_get_layer(s_output_layer));
}

static void playerConnected() {
  // window_set_background_color (if player icon is blue, then bg should be red, if player icon is red, bg should be blue)
  window_set_background_color(window, GColorFromRGB(255, 0, 0));
  text_layer_set_text(bottom_text_layer, "Connected");
  text_layer_set_text_color(bottom_text_layer, GColorFromRGB(255, 255, 255));
  
  // SETS SPECIFIED SVG ICON
  canvas_set_image(RESOURCE_ID_PLAYER_BLUE_ICON);
  // RED ICON
  // canvas_set_image(RESOURCE_ID_PLAYER_RED_ICON);
}

static void playerPalette() {
  // window_set_background_color
  window_set_background_color(window, GColorFromRGB(0, 170, 255));
  text_layer_set_text(bottom_text_layer, "No Items");
  text_layer_set_text_color(bottom_text_layer, GColorFromRGB(255, 255, 255));  
  
  // SETS SPECIFIED SVG ICON
  canvas_set_image(RESOURCE_ID_PALETTE_ICON);
}

static void roadRunner() {
  // window_set_background_color
  window_set_background_color(window, GColorFromRGB(255, 0, 0));
  text_layer_set_text(bottom_text_layer, "Road Runner");
  text_layer_set_text_color(bottom_text_layer, GColorFromRGB(255, 255, 255));
  
  // SETS SPECIFIED SVG ICON
  canvas_set_image(RESOURCE_ID_ROAD_RUNNER_ICON);
}

static void paintBomb() {
  // window_set_background_color
  window_set_background_color(window, GColorFromRGB(255, 170, 0));
  text_layer_set_text(bottom_text_layer, "Paint Bomb");
  text_layer_set_text_color(bottom_text_layer, GColorFromRGB(0, 0, 0));
  
  // SETS SPECIFIED SVG ICON
  canvas_set_image(RESOURCE_ID_PAINT_BOMB_ICON);
}

static void drySpell() {
  // window_set_background_color
  window_set_background_color(window, GColorFromRGB(170, 85, 255));
  text_layer_set_text(bottom_text_layer, "Dry Spell");
  text_layer_set_text_color(bottom_text_layer, GColorFromRGB(255, 255, 255));
  
  // SETS SPECIFIED SVG ICON
  canvas_set_image(RESOURCE_ID_DRY_SPELL_ICON);
}

static void manhole() {
  // window_set_background_color
  window_set_background_color(window, GColorFromRGB(0, 170, 255));
  text_layer_set_text(bottom_text_layer, "Manhole");
  text_layer_set_text_color(bottom_text_layer, GColorFromRGB(255, 255, 255));
  
  // SETS SPECIFIED SVG ICON
  canvas_set_image(RESOURCE_ID_MANHOLE_ICON);
}

static void drawItemScreen() {
  playerConnected();
  playerPalette();
  roadRunner();
  paintBomb();
  drySpell();
  manhole();
}

//
static void drawGameMode(int state) {
  resetScreen();
  drawItemScreen();
}


static void window_unload(Window *window) {
  text_layer_destroy(bottom_text_layer);
  text_layer_destroy(player_text_layer);
  // TODO kill image layer?
}

static void init(void) {
  window = window_create();
  window_set_click_config_provider(window, click_config_provider);
  window_set_window_handlers(window, (WindowHandlers) {
    .load = window_load,
    .unload = window_unload,
  });
  const bool animated = true;
  window_stack_push(window, animated);

  // Register AppMessage Callbacks
  app_message_register_inbox_received(inbox_received_callback);
  app_message_register_inbox_dropped(inbox_dropped_callback);
  app_message_register_outbox_failed(outbox_failed_callback);
  app_message_register_outbox_sent(outbox_sent_callback);

  // Open AppMessage in/out
  app_message_open(app_message_inbox_size_maximum(), app_message_outbox_size_maximum());

  // Subscribe to the accelerometer data service
  accel_subscribe();

  // DEBUG
  drawGameMode(0);
}


static void deinit(void) {
  accel_unsubscribe();
}


int main(void) {
  init();

  APP_LOG(APP_LOG_LEVEL_DEBUG, "Done initializing, pushed window: %p", window);

  app_event_loop();
  deinit();
}
