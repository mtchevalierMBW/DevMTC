// FormattingUtility
// Tested by: Utilities_TEST
public with sharing class FormattingUtility {

    // Format phone numbers (USA)
    public static String formatPhoneNbr(String phone) {
        String formatted = phone.replaceAll('\\D','');
        // Remove long distance indicator (1 + area + phone) to area + phone
        if (formatted.length()==11 && formatted.substring(0,1)=='1') {
            formatted = formatted.substring(1);
        }
        // Format standard US phone
        if (formatted.length()==10) {
            formatted = '(' + formatted.substring(0,3) + ') '
                      + formatted.substring(3, 6) + '-'
                      + formatted.substring(6);
        } else {  
            // don't reformat!
            formatted = phone;
        }
        return formatted;
    }

}