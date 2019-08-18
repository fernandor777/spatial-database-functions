package org.opengis.util;

import java.util.Locale;

public abstract interface InternationalString
  extends CharSequence, Comparable
{
  public abstract String toString(Locale paramLocale);
  
  public abstract String toString();
}


/* Location:           F:\Projects\SC4O\classes\
 * Qualified Name:     org.opengis.util.InternationalString
 * JD-Core Version:    0.7.0.1
 */