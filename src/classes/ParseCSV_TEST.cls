/**
 * ParseCSV_TEST
 * Tests: ParseCSV
 * Date: Mar 15, 2018
 * Programmer: Bryan Leaman
 *
 */
@isTest
private class ParseCSV_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupFFA() {
		//TestHelper_MW.createBaseFFAData(FFAdata);
		//FFAdata.refresh(); 
        //dealer.TestClassUtil tc = new dealer.TestClassUtil();
        //tc.insertDMSSettings();
	}

	// unitTest
	//---------------------------------------
	static testMethod void unitTest() {
		String simpletest = 'A,B,C\n1,2,3\n4,5,6\n,,';
		String stricttest = 'A,B,C\n"1","2,",3\n"4\n",5,6';
		
		//FFAdata.refresh(); 
		//System.runAs(FFAdata.TestUser) {
        	//TestHelper_MW th = new TestHelper_MW();
			ParseCSV simple = ParseCSV.SimpleParser();
			simple.setCsvData(simpletest);
			Map<Integer, Map<Integer,String>> simplemap = simple.getRowsMapByColumnNbr();
			
			
			ParseCSV strict = ParseCSV.StrictParser();
			strict.setCsvData(stricttest);
			Map<Integer, Map<String,String>> strictmap = strict.getRowsMapByColumnName();
			
		//}
	}
	
	// testNoHdgs
	//---------------------------------------
	static testMethod void testNoHdgs() {
		String simpletest = '1,2,3\n4,true,6,"seven"\n';
		
		//FFAdata.refresh(); 
		//System.runAs(FFAdata.TestUser) {
        	//TestHelper_MW th = new TestHelper_MW();
			ParseCSV simple = ParseCSV.SimpleParser();
			simple.hasColumnHeadings = false;
			simple.setCsvData(simpletest);
			Map<Integer, Map<Integer,String>> simplemap = simple.getRowsMapByColumnNbr();
			System.assert(simplemap.size()==2, 'Did not get 2 rows of heading-less data');
		//}
	}

}