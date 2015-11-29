package com.example.samples.app;

import android.app.Application;

/**
 * Created by tong on 15/11/29.
 */
public class SampleApplication extends Application {
    @Override
    public void onCreate() {
        super.onCreate();

        System.out.println("testString");
    }
}
