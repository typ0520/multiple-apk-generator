package com.example.samples;import com.example.samples2.R;

import android.app.Activity;
import android.os.Bundle;

/**
 * A login screen that offers login via email/password.
 */
public class LoginActivity extends Activity {
    public static final String s1 = "pretestStringsub";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_login);
    }

}

