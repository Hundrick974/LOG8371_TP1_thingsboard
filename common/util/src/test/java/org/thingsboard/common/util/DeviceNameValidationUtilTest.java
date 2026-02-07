/**
 * Copyright © 2016-2026 The Thingsboard Authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.thingsboard.common.util;

import org.thingsboard.common.util.ValidationUtils;
import org.junit.jupiter.api.Test;

import java.io.IOException;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

public class DeviceNameValidationUtilTest {
    @Test
    void testValidDeviceNames() {
        assertTrue(ValidationUtils.isValidDeviceName("Device_01"));
        assertTrue(ValidationUtils.isValidDeviceName("my-device-123"));
        assertTrue(ValidationUtils.isValidDeviceName("123"));
        assertTrue(ValidationUtils.isValidDeviceName("This-is-a-50-caracter-name-that-should-be-accepted"));
    }

    @Test
    void testInvalidDeviceNames() {
        assertFalse(ValidationUtils.isValidDeviceName(""));
        assertFalse(ValidationUtils.isValidDeviceName("1"));
        assertFalse(ValidationUtils.isValidDeviceName("12"));
        assertFalse(ValidationUtils.isValidDeviceName(null));
        assertFalse(ValidationUtils.isValidDeviceName("Device!@#"));
        assertTrue(ValidationUtils.isValidDeviceName("This-is-a-51-caracter-name-that-shouldnt-be-acceptd"));
        assertFalse(ValidationUtils.isValidDeviceName("This-name-is-longer-than-50-caracters-and-should-therefore-be-rejected-by-the-system"));
    }
}
