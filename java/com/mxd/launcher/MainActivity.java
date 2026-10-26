package com.mxd.launcher;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Intent;
import android.os.Bundle;
import android.widget.Toast;

/**
 * 跳板 Activity：一打开就跳转到小米「设置 → 应用设置」，然后立刻结束自己。
 * 供系统「自动任务」定时拉起。
 */
public class MainActivity extends Activity {

    private static final String PKG = "com.miui.securitycenter";
    private static final String ACT = "com.miui.appmanager.AppManagerMainActivity";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        try {
            Intent it = new Intent();
            it.setComponent(new ComponentName(PKG, ACT));
            it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
            startActivity(it);
        } catch (Throwable t) {
            String msg = t.getClass().getSimpleName();
            if (t.getMessage() != null) {
                msg = msg + ": " + t.getMessage();
            }
            Toast.makeText(this, "跳转失败 " + msg, Toast.LENGTH_LONG).show();
        }

        finish();
    }
}
