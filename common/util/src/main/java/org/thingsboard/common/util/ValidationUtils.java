package org.thingsboard.common.util;

public class ValidationUtils {

    public static boolean isValidDeviceName(String name) {
        if (name == null || name.isEmpty()) return false;
        if (name.length() > 50) return false;
        if (name.length() < 3) return false;
        return name.matches("^[a-zA-Z0-9_-]+$");
    }
}