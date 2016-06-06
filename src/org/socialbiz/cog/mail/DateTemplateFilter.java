package org.socialbiz.cog.mail;
 
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;
import java.util.TimeZone;

import com.x5.template.Chunk;
import com.x5.template.ChunkLocale;
import com.x5.template.filters.FilterArgs;
import com.x5.template.filters.ObjectFilter;
 
/**
 * Just call theme.registerFilter(new com.myapp.DateTimeFilter())
 * before rendering to use this handy |date filter.
 */
public class DateTemplateFilter extends ObjectFilter
{
    private static final String DEFAULT_FORMAT = "yyyy-MM-dd'T'HH:mm:ssZ";
 
    public String getFilterName()
    {
        return "date";
    }
 
    public Object transformObject(Chunk chunk, Object obj, FilterArgs arg)
    {
        if (!(obj instanceof Date)) {
            return "ERR: Not a java.util.Date";
        }
 
        Date date = (Date)obj;
 
        String format = null;
        String timezone = "UTC";
 
        String[] args = arg.getFilterArgs();
        if (args != null) {
            if (args.length == 1) {
                format = args[0];
            } else if (args.length > 1) {
                format = args[0];
                timezone = args[1].trim();
            }
        }
 
        if (format == null || format.trim().length() == 0) format = DEFAULT_FORMAT;
 
        try {
            ChunkLocale chunkLocale = chunk.getLocale();
            Locale javaLocale = chunkLocale == null ? null : chunkLocale.getJavaLocale();
            SimpleDateFormat formatter = javaLocale == null
                ? new SimpleDateFormat(format)
                : new SimpleDateFormat(format, javaLocale);
            formatter.setTimeZone(TimeZone.getTimeZone(timezone));
            return formatter.format(date);
        } catch (IllegalArgumentException e) {
            return e.getMessage();
        }
    }
}

