package com.example.flutterapod;

import java.io.IOException;

import android.app.WallpaperManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.util.DisplayMetrics;
import android.os.Environment;
import android.view.WindowManager;

import android.os.Bundle;
import io.flutter.app.FlutterActivity;
import io.flutter.plugins.GeneratedPluginRegistrant;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class MainActivity extends FlutterActivity {
  private static final String CHANNEL = "samples.flutter.io/wallpaper";

    @Override
    public void onCreate(Bundle savedInstanceState) {

        super.onCreate(savedInstanceState);
        GeneratedPluginRegistrant.registerWith(this);

        new MethodChannel(getFlutterView(), CHANNEL).setMethodCallHandler(
                new MethodCallHandler() {
                    @Override
                    public void onMethodCall(MethodCall call, Result result) {
                      if (call.method.equals("setWallpaper")) {
                          String path = call.argument("path");
                          System.out.print(path);
                          int setWallpaperResult = setWallpaper(path);

                          if (setWallpaperResult != 0) {
                              result.success(setWallpaperResult);
                          } else {
                              result.error("UNAVAILABLE", "Can not set wallpaper.", null);
                          }
                      } else {
                          result.notImplemented();
                      }
                    }
                });
    }

  private int setWallpaper(String path) {
    DisplayMetrics displayMetrics = new DisplayMetrics();
    getWindowManager().getDefaultDisplay().getMetrics(displayMetrics);
    int height = displayMetrics.heightPixels;
    int width = displayMetrics.widthPixels << 1; // best wallpaper width is twice screen width

    // First decode with inJustDecodeBounds=true to check dimensions
    final BitmapFactory.Options options = new BitmapFactory.Options();
    options.inJustDecodeBounds = true;
    BitmapFactory.decodeFile(path);

    // Calculate inSampleSize
    //options.inSampleSize = calculateInSampleSize(options, width, height);

    // Decode bitmap with inSampleSize set
    //options.inJustDecodeBounds = false;
    Bitmap decodedSampleBitmap = BitmapFactory.decodeFile(path);

    WallpaperManager wm = WallpaperManager.getInstance(this);
    try {
        wm.setBitmap(decodedSampleBitmap);
        return 1;
    } catch (IOException e) {
        //Log.e(TAG, "Cannot set image as wallpaper", e);
        return 0;
    }
  }
}
