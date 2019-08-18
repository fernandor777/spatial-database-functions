package org.geotools.util.logging;

import java.util.logging.Logger;

public class Logging {

    public Logging() {
    }

    public static Logger getLogger(String _name) {
        return Logger.getLogger( _name );
    }
    
    public static Logger getLogger(Class _class) {
        return Logger.getLogger( _class.getName() );
    }
    
    public static void unexpectedException(Class _class,  
                                           String _type, 
                                           Exception _exception) {
      if (_type.equalsIgnoreCase("remove") )
          return;
    }

    public static void unexpectedException(Class _class,  String _type, AssertionError _error) {
      if (_type.equalsIgnoreCase("remove") )
          return;
    }
  
}
