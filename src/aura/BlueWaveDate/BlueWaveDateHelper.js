({
    // dateString is yyyy-mm-dd
    getFormattedDate : function(dateString) {
        var parts = dateString.split('-');

        var year = parts[0];

        var month = parts[1];
        month = month.length > 1 ? month : '0' + month;

        var day = parts[2];
        day = day.length > 1 ? day : '0' + day;
  
        return month + '/' + day + '/' + year;
    }    
})