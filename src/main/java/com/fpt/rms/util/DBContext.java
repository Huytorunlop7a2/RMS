package com.fpt.rms.util;

import java.io.InputStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

public final class DBContext {
    private static final String URL;
    private static final String USERNAME;
    private static final String PASSWORD;

    static {
        try {
            Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
            Properties p = new Properties();
            try (InputStream in = DBContext.class.getClassLoader().getResourceAsStream("db.properties")) {
                if (in == null)
                    throw new IllegalStateException("Không tìm thấy db.properties");
                p.load(in);
            }
            URL = envOrDefault("DB_URL", p.getProperty("db.url"));
            USERNAME = envOrDefault("DB_USERNAME", p.getProperty("db.username"));
            PASSWORD = envOrDefault("DB_PASSWORD", p.getProperty("db.password"));
        } catch (Exception e) {
            throw new ExceptionInInitializerError(e);
        }
    }

    private DBContext() {
    }

    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(URL, USERNAME, PASSWORD);
    }

    private static String envOrDefault(String name, String fallback) {
        String value = System.getenv(name);
        return value == null || value.isBlank() ? fallback : value;
    }
}
