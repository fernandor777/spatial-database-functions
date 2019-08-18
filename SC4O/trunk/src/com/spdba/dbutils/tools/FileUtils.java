package com.spdba.dbutils.tools;

import java.io.File;
import java.io.IOException;

public class FileUtils {
    
    public static final String DEFAULT_OUTPUT_DIRECTORY = System.getProperty("java.io.tmpdir");

    public static String getDirectory(String _filename) {
        if (Strings.isEmpty(_filename)) {
            return null;
        }
        File f = new File(_filename);
        String dir = f.getParent();
        if (Strings.isEmpty(dir)) {
            return dir;
        }
        int lastIndex = dir.indexOf("\\")!=-1 ? dir.lastIndexOf("\\") : dir.lastIndexOf("/");
        if ( lastIndex != dir.length() ) {
            dir += dir.indexOf("\\")!=-1 ? "\\" : "/";
        }
        return dir;
    }

    /**
     * Builds a valid, fully specified, file path
     */ 
    public static String FileNameBuilder( String outputDir,  /* output directory with separator on end */
                                          String fileName,  /* filename without suffix */
                                          String fileSuffix /* SHP, DBF, TAB, SHX, PRJ, GML, KML etc */ ) 
    throws IllegalArgumentException 
    {
        
        if (Strings.isEmpty(outputDir) ) {
            throw new IllegalArgumentException("no output directory");
        }
        if (Strings.isEmpty(fileName)) {
            throw new IllegalArgumentException("no output filename specified");
        }
        if (Strings.isEmpty(fileSuffix)) {
            throw new IllegalArgumentException("no output filename suffix eg shp specified.");
        }
    
        int loc;
        loc = outputDir.lastIndexOf(File.separatorChar);
        if (loc == -1) {
            outputDir = File.separatorChar + outputDir; 
        } else {
            // Add separatorChar at end of outputDir if not already the last char
            if ( outputDir.charAt(outputDir.length()-1) != File.separatorChar )
                outputDir += File.separatorChar;
        }
        loc = fileName.lastIndexOf(".");
        if (loc != -1) {
            fileName = fileName.substring(0, loc);
        }
        fileSuffix = fileSuffix.replaceAll("[.]","");
        return outputDir + fileName + "." + fileSuffix;
    }

    public static String getFileNameFromPath(String  _path,
                                             boolean _noSuffix) {
        String filename = null;
        int lastIndex;
        
        if (_path != null && _path.trim().length() > 0) {
            _path = _path.trim();
            if (! ( _path.endsWith("\\") || _path.endsWith("/")) ) {
                filename = _path;
                lastIndex = _path.indexOf("\\")!=-1 ? _path.lastIndexOf("\\") : _path.lastIndexOf("/"); 
                if (lastIndex >= 0) {
                    filename = _path.substring(lastIndex + 1, _path.length());
                }
            }
            if ( _noSuffix && filename.indexOf(".") > 0 ) {
                filename = filename.substring(0,filename.indexOf("."));
            }
       }
       return filename;
     }

    public static int RunCommand(String _command) 
    throws IOException 
    {
        int exitVal = 0;
        try
        {
            Runtime rt = Runtime.getRuntime();
            Process proc = rt.exec(_command);
            proc.waitFor();
            exitVal = proc.exitValue();
        }
        catch(Exception e)
        {
            throw new IOException("FileUtils.RunCommand(" + _command + ") Filed with: " + e.getMessage());
        }
        return exitVal;
    }

}
