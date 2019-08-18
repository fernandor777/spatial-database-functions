package com.spdba.dbutils.tools;

public class LOGGER {
    
    private String CLASS_PATH = null;
    
    public LOGGER(String _class_path) {
        super();
        CLASS_PATH = _class_path;
    }

    public String getClassPath() {
        return CLASS_PATH;
    }

    public static void severe   (String _message) {error(_message);}
    public static void error    (String _message) {if (_message!=null) { System.err.println("error:" + _message); } }
    public static void warning  (String _message) {warn(_message);}
    public static void warn     (String _message) {System.out.println("warn: " + _message); }
    public static void debug    (String _message) {System.out.println("debug:" + _message); }
    public static void debug    (int    _message) {System.out.println("debug:" + _message); }
    public static void info     (String _message) {System.out.println("info: " + _message); }
    public static void info     (int    _message) {System.out.println("info: " + _message); }
    public static void config   (String _message) {System.out.println("config: " + _message);}
    public static void fine     (String _message) {System.out.println("debug: " + _message); }
    public static void finer    (String _message) {System.out.println("debug: " + _message); }
    public static void finest   (String _message) {System.out.println("trace: " + _message); }

    
}
