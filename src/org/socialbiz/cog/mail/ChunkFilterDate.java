package org.socialbiz.cog.mail;

import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;

import com.purplehillsbooks.xml.Mel;
import com.x5.template.Chunk;
import com.x5.template.filters.BasicFilter;
import com.x5.template.filters.ChunkFilter;
import com.x5.template.filters.FilterArgs;

/**
G   Era designator  Text    AD
y   Year    Year    1996; 96
Y   Week year   Year    2009; 09
M   Month in year   Month   July; Jul; 07
w   Week in year    Number  27
W   Week in month   Number  2
D   Day in year     Number  189
d   Day in month    Number  10
F   Day of week in month    Number  2
E   Day name in week    Text    Tuesday; Tue
u   Day number of week (1 = Monday, ..., 7 = Sunday)    Number  1
a   Am/pm marker    Text    PM
H   Hour in day (0-23)  Number  0
k   Hour in day (1-24)  Number  24
K   Hour in am/pm (0-11)    Number  0
h   Hour in am/pm (1-12)    Number  12
m   Minute in hour  Number  30
s   Second in minute    Number  55
S   Millisecond     Number  978
z   Time zone   General time zone   Pacific Standard Time; PST; GMT-08:00
Z   Time zone   RFC 822 time zone   -0800
X   Time zone   ISO 8601 time zone  -08; -0800; -08:00

SPECIAL EXTENTION:  'ttt' will be replaced with timezone ID
it must be put in single quotes to hid from normal date format processing

USE THIS in a TEMPLATE:

     {$myDate|date(YYYY-MM-dd)}
     {$myDate|date("MMM dd, YYYY  HH:mm 'GMT'XXX")
     {$myDate|date("MMM dd, YYYY  HH:mm '(ttt)' ")

 */
public class ChunkFilterDate  extends BasicFilter implements ChunkFilter {
    private Calendar cal;
   
    public ChunkFilterDate(Calendar _cal) {
        cal = _cal;
        /*
        timeZoneID = _timeZoneID;
        if (timeZoneID!=null) {
            TimeZone tz =  TimeZone.getTimeZone(timeZoneID);
            cal = Calendar.getInstance(tz);
        }
        else {
            cal = Calendar.getInstance();
        }
        */
    }

    @Override
    public String transformText(Chunk chunk, String valueIn, FilterArgs args) {
        long dateVal = Mel.safeConvertLong(valueIn);

        //if this is zero, or close enough to zero, then suppress output
        //we give about 1 day of slop in case someone distorted things with
        //a timezone offset.
        if (dateVal < 100000000L) {
            return "";
        }
        String[] argStrings = args.getFilterArgs();
        String format = "MMM dd, yyyy  HH:mm '(ttt)'";
        if (argStrings.length>0 && argStrings[0].length()>0) {
            format = argStrings[0];
        }
        SimpleDateFormat sdf = new SimpleDateFormat(format);
        sdf.setCalendar(cal);
        String res = sdf.format(new Date(dateVal));
        if (res.contains("ttt")) {
            res = res.replace("ttt", cal.getTimeZone().getID());
        }
        return res;
    }

    @Override
    public String getFilterName() {
        return "date";
    }
}