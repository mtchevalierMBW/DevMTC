/**
 * ParseCSV
 * Tested by: ParseCSV_TEST
 * Date: Mar 15, 2018
 * Programmer: Bryan Leaman
 *
 * simple parsing doesn't handle embedded new lines or commas in the data
 * strict parsing *does* handle embedded new lines and commas in the data
 * 
 * Usage:
 *	String simpletest = 'A,B,C\n1,2,3\n4,5,6';
 *	ParseCSV simple = ParseCSV.SimpleParser();
 *	simple.setCsvData(simpletest);
 *	Map<Integer, Map<Integer,String>> simplemap = simple.getRowsMapByColumnNbr();
 *			
 *	String stricttest = 'A,B,C\n"1","2,",3\n"4\n",5,6';
 *	ParseCSV strict = ParseCSV.StrictParser();
 *	strict.setCsvData(stricttest);
 *	Map<Integer, Map<String,String>> strictmap = strict.getRowsMapByColumnName();
 *
 * Code coverage:
 *	2018-03-15	95% (118/123)
 *	2018-08-13	95% (152/160)
 *	2018-10-29	84% (140/165)
 * 
 * Modification log:
 *	2018-07-09	B. Leaman	BLL1 - allow for alternate delimiters and missing column headings (for Concur import)
 *	2018-08-10	B. Leaman	BLL2 - handle "no string delimiter" (Concur payables import)
 *	2018-10-29	B. Leaman	BLL3 - automatically ignore blank lines (unless new flag is set to include blank lines)
 * 
 */
public with sharing class ParseCSV {

	private String method;
	private String csvData;
	private Integer cursor;
	public Integer LineNbr {get;private set;}
	private List<String> colHdgs;
	private Set<String> byteOrderMarksHex = new Set<String>{'efbbbf', 'feff', 'fffe'}; 
	public String encodedNewLine {get;set;}
	public boolean debug;
	// BLL1a
	public String fieldDelimiter {get;set;}
	public String stringDelimiter {get;set;}
	public boolean hasColumnHeadings {get;set;}
	// BLL1a end
	// BLL3a
	public boolean ignoreBlankLines {get;set;}
	// BLL3a end

	// ParseCSV constructor
	//---------------------------------------
	public ParseCSV() {	
		method = 'simple';
		csvData = '';
		cursor = 0;
		LineNbr = 0;
		debug = false;
		fieldDelimiter = ',';	// BLL1a
		stringDelimiter = '"';	// BLL1a
		hasColumnHeadings = true;	// BLL1a
		ignoreBlankLines = true;	// BLL3a
	}

	// SimpleParser - constructor
	public static ParseCSV SimpleParser() {
		ParseCSV p = new ParseCSV();
		p.method = 'simple';
		return p;
	}

	// StrictParser - constructor
	public static ParseCSV StrictParser() {
		ParseCSV p = new ParseCSV();
		p.method = 'strict';
		p.encodedNewLine = '<<newline>>';
		return p;
	}

	// setCsvData
	public void setCsvData(String d) {
		csvData = d;
		if (debug) System.debug('setCsvData:' + (d!=null ? d.left(80) : 'null'));
		stripUnicodeMarker();
		if (method=='strict' && encodedNewline!=null) csvData = encodeQuotedNewline(csvData);
	}

	// stripUnicodeMarker
	private void stripUnicodeMarker() {
		// strip utf-8 byte order encoding (if present at beginning of data)
		String hexByte = null;
		if (csvData.length()>0) hexByte = EncodingUtil.convertToHex(Blob.valueOf(csvData.substring(0,1))); 
		if (byteOrderMarksHex.contains(hexByte)) {
			if (debug) System.debug('stripUnicodeMarker: ' + hexByte);
			csvData = csvData.substring(1);
		}
	}

	// getColumnNames 
	public List<String> getColumnNames() {
		// assume 0 offset starting point & don't adjust cursor unless it's still 0
		// so column names can be retrieved after initial processing
		if (colHdgs==null && hasColumnHeadings) {	// BLL1c
			System.debug(method);
			Integer nl = csvData.indexOf('\n');
			if (nl<0) nl = csvData.length();
			String row1 = csvData.substring(0,nl);
			if (cursor==0) cursor = nl+1;
			//BLL1d List<String> tmpHdgs = row1.split(',');
			if (debug) System.debug(fieldDelimiter);
			List<String> tmpHdgs = row1.split(fieldDelimiter);	// BLL1a
			if (debug) System.debug(tmpHdgs);
			colHdgs = new List<String>();
			//BLL1d for(String c : tmpHdgs) colHdgs.add(c.trim().toLowerCase().replace('"',''));
			if (!String.isBlank(stringDelimiter)) for(String c : tmpHdgs) colHdgs.add(c.trim().toLowerCase().replace(stringDelimiter,''));	// BLL1a, BLL2c
			if (debug) System.debug('read column headings: ' + String.join(colHdgs, ','));
		} 
		return colHdgs;
	}

	// getNextLine
	private String getNextLine() {
		String l;
		Integer nl = csvData.indexOf('\n',cursor);

		if (debug) System.debug('getNextLine found newline at ' + nl + ' starting from ' + cursor);
		if (nl<0) nl = csvData.length();
		if (nl>cursor) l = csvData.substring(cursor,nl);
		cursor = nl+1;
		if (debug) System.debug('getNextLine: newline found at position: ' + String.valueOf(nl));
		if (debug) System.debug('getNextLine: new cursor position: ' + String.valueOf(cursor));
		if (debug) System.debug('getNextLine: ' + l);
		//System.debug(nl);
		//System.debug(l);
		//System.debug(cursor);

		return l;
	}

	public List<String> getNextRowData() {
		List<String> row;
		List<String> rawrow = new List<String>();

		boolean rowIsEmpty = false;	// BLL3a
		boolean endOfData = false; // BLL3a
		do {	// BLL3a
			String line = getNextLine();
			endOfData = line==null;
			LineNbr++;
			if (debug) System.debug('getNextRowData line#:' + String.valueOf(LineNbr));

			// replace double-quotes that indicate empty fields with just no value
			//BLL1d while (line!=null && line.indexOf(',"",')>=0) line = line.replace(',"",', ',,');
			String emptyQuotedColumn = fieldDelimiter + stringDelimiter + stringDelimiter + fieldDelimiter;	// BLL2c
			String emptyColumn = fieldDelimiter + fieldDelimiter;
			while (!String.isBlank(stringDelimiter) && line!=null && line.indexOf(emptyQuotedColumn)>=0)	// BLL2c 
				line = line.replace(emptyQuotedColumn, emptyColumn);	// BLL1a
			if (debug) System.debug(line);
			row = new List<String>();

			if (method=='strict') {
				if (line!=null) rawrow = getRowDataStrict(line);
			} else {
				//if (line!=null) rawrow = line.split(',');
				System.debug(fieldDelimiter);
				if (line!=null) rawrow = line.split(fieldDelimiter);
				if (debug) System.debug(rawrow);
			}

			// remove leading and trailing double-quotes
			for(String d : rawrow) {
				d = d.trim();
				//while (d.startsWith('"') && d.endsWith('"')) d = d.removeStart('"').removeEnd('"');
				while (!String.isBlank(stringDelimiter) && d.startsWith(stringDelimiter) && d.endsWith(stringDelimiter))	// BLL2c 
					d = d.removeStart(stringDelimiter).removeEnd(stringDelimiter);
				row.add(d);
			}
			rowIsEmpty = String.isBlank(String.join(row,''));	// BLL3a
			System.debug(row);
			System.debug(rowIsEmpty);
		} while (!endOfData && ignoreBlankLines && rowIsEmpty);	// BLL3
		if (debug && row!=null) System.debug('getNextRowData: ' + String.join(row, ','));		
		return row;
	}


	// getRowsMapByColumnNbr
	public Map<Integer,Map<Integer,String>> getRowsMapByColumnNbr() {
		Map<Integer,Map<Integer,String>> rtnMap = new Map<Integer,Map<Integer,String>>();
		if (hasColumnHeadings) List<String> columns = getColumnNames();
		Integer rowNbr = 0;
		List<String> row = getNextRowData();
		if (debug) System.debug(row);
		while (row!=null && row.size()>0) {
			if (debug) System.debug(row);
			Map<Integer,String> colMap = new Map<Integer,String>();
			Integer colNbr = 0;
			for(String d : row) colMap.put(++colNbr, d);
			rtnMap.put(++rowNbr, colMap);
			row = getNextRowData();
		}
		return rtnMap;
	}


	// getRowsMapByColumnName
	public Map<Integer,Map<String,String>> getRowsMapByColumnName() {
		Map<Integer,Map<String,String>> rtnMap;
		if (hasColumnHeadings) {
			rtnMap = new Map<Integer,Map<String,String>>();
			List<String> columns = getColumnNames();
			Integer rowNbr = 0;
			List<String> row = getNextRowData();
			while (row!=null && row.size()>0) {
				Map<String,String> colMap = new Map<String,String>();
				Integer colNbr = 0;
				for(String d : row) {
					++colNbr;
					String colname = (colNbr>0 && colNbr<=columns.size()) ? columns[colNbr-1] : '';
					if (String.isBlank(colname)) colname = 'col#'+String.valueOf(colNbr);
					colMap.put(colname, d);
				}
				rtnMap.put(++rowNbr, colMap);
				row = getNextRowData();
			}
		}
		return rtnMap;
	}


	// getRowDataStrict - handle embedded newlines and commas
	private List<String> getRowDataStrict(String line) {
		// Split csv line into columns (handle quoted strings with commas!)
		// handle commas in quoted values: field1, "John, Amy Smith", field3
		// ignore quotes inside strings (dbl-quoted):  "This is a ""quoted"" string."
		List<String> coldata = new List<String>();
		boolean inquote = false;
		Integer start = 0;
		Integer i=0;
		for(i=0; i<line.length(); i++) {
			//BLL1d if (line.substring(i, i+1)=='"' && line.length()>i+1 && line.substring(i+1, i+2)=='"') {
			if (!String.isBlank(stringDelimiter) && line.substring(i, i+1)==stringDelimiter && line.length()>i+1 && line.substring(i+1, i+2)==stringDelimiter) {	// BLL1a, BLL2c
				if (inquote) i++;
			} else {
				//BLL1d if (line.substring(i, i+1)=='"') inquote = !inquote;
				if (!String.isBlank(stringDelimiter) && line.substring(i, i+1)==stringDelimiter)	// BLL2c 
					inquote = !inquote;	// BLL1a
			}
			//BLL1d if (line.length()>=i+1 && line.substring(i ,i+1)==',' && !inquote) {
			if (line.length()>=i+1 && line.substring(i ,i+1)==fieldDelimiter && !inquote) {	// BLL1a
				String fldvalue = line.substring(start, i).trim();
				// remove begin/end quotes
				//BLL1d if (fldvalue.startsWith('"') && fldvalue.endsWith('"')) fldvalue = fldvalue.removeStart('"').removeEnd('"');
				//BLL1d fldvalue = fldvalue.replace('""', '"');	// dbl-quotes to single quotes
				if (!String.isBlank(stringDelimiter) && fldvalue.startsWith(stringDelimiter) && fldvalue.endsWith(stringDelimiter))	// BLL2c 
					fldvalue = fldvalue.removeStart(stringDelimiter).removeEnd(stringDelimiter);	// BLL1a
				if (!String.isBlank(stringDelimiter))	// BLL2a 
					fldvalue = fldvalue.replace((stringDelimiter+stringDelimiter), stringDelimiter);	// dbl-quotes to single quotes	// BLL1a
				//System.debug(fldvalue);
				fldvalue = decodeQuotedNewline(fldvalue);
				//System.debug(fldvalue);
				coldata.add(fldvalue);
				start = i+1;
			}
		}
		// last column...
		String fldvalue = line.substring(start).trim();
		// remove begin/end quotes
		//BLL1d if (fldvalue.startsWith('"') && fldvalue.endsWith('"')) fldvalue = fldvalue.removeStart('"').removeEnd('"');
		//BLL1d fldvalue = fldvalue.replace('""', '"');	// dbl-quotes to single quotes
		if (!String.isBlank(stringDelimiter) && fldvalue.startsWith(stringDelimiter) && fldvalue.endsWith(stringDelimiter))	// BLL2c 
			fldvalue = fldvalue.removeStart(stringDelimiter).removeEnd(stringDelimiter);	// BLL1a
		if (!String.isBlank(stringDelimiter))	// BLL2a 
			fldvalue = fldvalue.replace((stringDelimiter+stringDelimiter), stringDelimiter);	// dbl-quotes to single quotes	// BLL1a
		//System.debug(fldvalue);
		fldvalue = decodeQuotedNewline(fldvalue);
		//System.debug(fldvalue);
		coldata.add(fldvalue);
			
		//System.debug('data columns=' + String.valueOf(coldata.size()));
		return coldata;
	}


	// encodeQuotedNewline
	private String encodeQuotedNewline(String s) {
		String result = '';
		Integer pos = 0;
		//Integer q = s.indexOf('"', pos);
		Integer q = String.isBlank(stringDelimiter) ? -1 : s.indexOf(stringDelimiter, pos);	// BLL2c
		// found open quote...
		while (q>=0) {

			// from last-used close-quote position to current quote position
			result += s.substring(pos, q);

			// find close quote
			//BLL1d if (s.length()>=q+1 && s.substring(q,q+1)=='"') {
				// BLL1d pos = s.indexOf('"', q+1);
			if (s.length()>=q+1 && s.substring(q,q+1)==stringDelimiter) {	// BLL1a
				pos = s.indexOf(stringDelimiter, q+1);	// BLL1a
				// skip "", which are quotes within a quoted string.
				//BLL1d while(pos>=0 && s.length()>=pos+2 && s.substring(pos,pos+2)=='""') {
				//BLL1d		pos = s.indexOf('"', pos+2);
				while(pos>=0 && s.length()>=pos+2 && s.substring(pos,pos+2)==(stringDelimiter+stringDelimiter)) {	// BLL1a
					pos = s.indexOf(stringDelimiter, pos+2);	// BLL1a
				}
				if (pos<0) pos = s.length();
			} else pos = q+1; 

			//System.debug(q);
			//System.debug(pos);
			if (pos>=q) result += s.substring(q,pos).replace('\n', encodedNewLine);
			else result += s.substring(q);

			//BLL1d q = s.indexOf('"', pos+1);	// find next open quote
			q = s.indexOf(stringDelimiter, pos+1);	// find next open quote
		}
		//System.debug(pos);
		if (pos>=0) result += s.substring(pos);
		return result;
	}

	// decodeQuotedNewline
	private String decodeQuotedNewline(String s) {
		return s.replace(encodedNewLine, '\n');
	}


}