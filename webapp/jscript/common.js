// Please add all the common function here.

function DaysInBetweenDates(date1, date2) {

    // The number of milliseconds in one day
    var ONE_DAY = 1000 * 60 * 60 * 24

    // Convert both dates to milliseconds
    var date1_ms = date1.getTime();
    var date2_ms = date2.getTime();

    // Calculate the difference in milliseconds
    var difference_ms = Math.abs(date1_ms - date2_ms)

    // Convert back to days and return
    return Math.round(difference_ms / ONE_DAY)

}

function DateAdd(objDate, strInterval, intIncrement)
{
    if(typeof(objDate) == "string")
    {
        objDate = new Date(objDate);

        if (isNaN(objDate))
        {
            throw("DateAdd: Date is not a valid date");
        }
    }
    else if(typeof(objDate) != "object" || objDate.constructor.toString().indexOf("Date()") == -1)
    {
        throw("DateAdd: First parameter must be a date object");
    }

    if(strInterval != "M"
        && strInterval != "D"
        && strInterval != "Y"
        && strInterval != "h"
        && strInterval != "m"
        && strInterval != "uM"
        && strInterval != "uD"
        && strInterval != "uY"
        && strInterval != "uh"
        && strInterval != "um"
        && strInterval != "us")
    {
        throw("DateAdd: Second parameter must be M, D, Y, h, m, uM, uD, uY, uh, um or us");
    }

    if(typeof(intIncrement) != "number")
    {
        throw("DateAdd: Third parameter must be a number");
    }

    switch(strInterval)
    {
        case "M":
        objDate.setMonth(parseInt(objDate.getMonth()) + parseInt(intIncrement));
        break;

        case "D":
        objDate.setDate(parseInt(objDate.getDate()) + parseInt(intIncrement));
        break;

        case "Y":
        objDate.setYear(parseInt(objDate.getYear()) + parseInt(intIncrement));
        break;

        case "h":
        objDate.setHours(parseInt(objDate.getHours()) + parseInt(intIncrement));
        break;

        case "m":
        objDate.setMinutes(parseInt(objDate.getMinutes()) + parseInt(intIncrement));
        break;

        case "s":
        objDate.setSeconds(parseInt(objDate.getSeconds()) + parseInt(intIncrement));
        break;

        case "uM":
        objDate.setUTCMonth(parseInt(objDate.getUTCMonth()) + parseInt(intIncrement));
        break;

        case "uD":
        objDate.setUTCDate(parseInt(objDate.getUTCDate()) + parseInt(intIncrement));
        break;

        case "uY":
        objDate.setUTCFullYear(parseInt(objDate.getUTCFullYear()) + parseInt(intIncrement));
        break;

        case "uh":
        objDate.setUTCHours(parseInt(objDate.getUTCHours()) + parseInt(intIncrement));
        break;

        case "um":
        objDate.setUTCMinutes(parseInt(objDate.getUTCMinutes()) + parseInt(intIncrement));
        break;

        case "us":
        objDate.setUTCSeconds(parseInt(objDate.getUTCSeconds()) + parseInt(intIncrement));
        break;
    }
    return objDate;
}
