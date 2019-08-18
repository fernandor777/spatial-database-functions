/*
 *    GeoTools - OpenSource mapping toolkit
 *    http://geotools.org
 *    (C) 2003-2006, Geotools Project Managment Committee (PMC)
 *    (C) 2001, Institut de Recherche pour le Développement
 *
 *    This library is free software; you can redistribute it and/or
 *    modify it under the terms of the GNU Lesser General Public
 *    License as published by the Free Software Foundation; either
 *    version 2.1 of the License, or (at your option) any later version.
 *
 *    This library is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *    Lesser General Public License for more details.
 */
package org.geotools.resources;

import java.text.MessageFormat;


/**
 * {link java.util.ResourceBundle} implementation using integers instead of strings for resource
 * keys. Because it doesn't use strings, this implementation avoids adding all those string
 * constants to {@code .class} files and runtime images. Developers still have meaningful labels
 * in their code (e.g. {@code DIMENSION_MISMATCH}) through a set of constants defined in interfaces.
 * This approach furthermore gives the benefit of compile-time safety. Because integer constants are
 * inlined right into class files at compile time, the declarative interface is never loaded at run
 * time. This class also provides facilities for string formatting using {@link MessageFormat}.
 *
 * @since 2.0
 * @source $URL: http://svn.geotools.org/tags/2.4.5/modules/library/metadata/src/main/java/org/geotools/resources/ResourceBundle.java $
 * @version $Id: ResourceBundle.java 26165 2007-07-06 17:02:26Z desruisseaux $
 * @author Martin Desruisseaux
 *
 * @deprecated Renamed as {@link IndexedResourceBundle}.
 */
public class ResourceBundle extends IndexedResourceBundle {
    /**
     * Constructs a new resource bundle. The resource filename will be inferred
     * from the fully qualified classname of this {@code ResourceBundle} subclass.
     *
     * @since 2.2
     */
    protected ResourceBundle() {
        super();
    }

    /**
     * Constructs a new resource bundle.
     *
     * @param filename The resource name containing resources.
     *        It may be a filename or an entry in a JAR file.
     */
    protected ResourceBundle(final String filename) {
        super(filename);
    }
}
