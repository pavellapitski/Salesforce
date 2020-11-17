public class HTMLParser {

    public static final string PARSER_EXCEPTION = 'Exception during Page Pasering';
    
    public class ParserException extends Exception {
    }    
    
    private Integer nextTd;
    private String rawData;
    
    public HTMLParser(String file, String name, Integer columnsToSkip) {
        rawData=file;
        nextTd = 0;
        String licRow = '>' + name + '</th>';
        for (Integer i = 0; i < columnsToSkip; i++) licRow += '<td class=" dataCell  ">';
        Integer licLen = licRow.length();
        Integer pos = rawData.indexOf(licRow);

        if (pos == -1) throw new ParserException(PARSER_EXCEPTION);
        nextTd = pos + licLen;
    }
    
    public String parseField() {
        String licRow = '<td class=" dataCell  numericalColumn">';
        Integer licLen = licRow.length();
        Integer pos = rawData.indexOf(licRow, nextTd);
        Integer licStart = pos + licLen;
        nextTd = rawData.indexOf('</td>', licStart);
        return rawData.substring(licStart, nextTd).replaceAll(',', '').replaceAll(' ', '').replaceAll('&nbsp;', ' ');
    }      
}