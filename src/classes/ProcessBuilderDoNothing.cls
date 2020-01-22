/**
 * ProcessBuilderDoNothing
 * Tested by: ProcessBuilderDoNothing_TEST
 * Date: 2018-12-14
 * Programmer: Bryan Leaman
 * Work item: W-000528
 *
 * Code Coverage
 *	2018-12-14	100%	(1/1)
 *
 * Modification Log
 *	Date		Developer	Work item/mod#	Description
 *	----------	-----------	--------------	------------------------------------------------
 *
**/
public with sharing class ProcessBuilderDoNothing {
 
	// doNothing - used to fill the requirement of process builder's to have
	// at lest one action.
	//---------------------------------------
	@InvocableMethod(label='DoNothing' description='Used to fulfill requirement of having an action in process builder')
	public static void doNothing () {
	}

}