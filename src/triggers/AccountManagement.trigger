/**
 * AccountManagement
 * Tested by: AccountManagement_TEST
 * 
 * 2015-05-13  B. Leaman  Correct use of user division to assign account store if not specified
 * 2015-05-29  B. Leaman  Copy person account field data into dealerteam custom "person account" fields
 * 2015-06-25  B. Leaman  Default accts payable and accts receivable.
 * 2015-07-21  B. Leaman  Only assign locations when adding non-vendor, non-payor accounts.
 *                        (Avoid assigning locations on unrelated mass updates!)
 * 2015-07-30  B. Leaman  Other FF fields must be populated for all accounts, not just person accounts.
 *                        Removed person acct conditional update for currency, terms, etc. & update
 *                        these based on record type (vendor vs other) as with AR & AP GL accounts.
 * 2015-08-06  B. Leaman  BLL6 - Per Jackie Brady -- need AP acct# on customer accts for refunds.
 * 2015-08-13  B. Leaman  BLL7 - reduce queries where possible, don't query user or location if
 *                        not needed.
 * 2015-08-21  B. Leaman  BLL8 - Remove setting AP control account for non-vendors per Jackie Brady;
 *                        It's causing accounts with credits to show up for payment (e.g. if they have made a deposit)
 * NO: Causes test failures: 2015-09-02  B. Leaman  BLL9 - force vendor flag off if not a vendor record type
 * 2015-09-04  B. Leaman  BLL10 - Set vendor default payment method to 'Check' if missing
 * 2015-09-21   B. Leaman   BLL11 - Set vendor terms days offset & discount based on existance of description because the
 *                          other fields apparently default to 0, not null.
 * 2015-09-30   B. Leaman   BLL12 - Set Do Not Call, Email Opt Out, Mail Opt Out for deceased or out of business accts.
 * IN PROCESS:
 * 2015-11-27   B. Leaman   BLL13 - Duplicate sales tax status and exemption cert fields -- keep in sync with FF fields.
 * 2016-01-05   B. Leaman   BLL14 - Continue to process additional desired vehicles from Pardot as done for leads.
 * 2016-01-22   B. Leaman   BLL15 IT18920 - Use gl 1100 for 3rd party payor receivables per Michele Swindell
 * 2016-02-24   B. Leaman   BLL16 Allow removal of home phone number to work.
 * 2016-05-02   B. Leaman   BLL17 Desired vehicles on person account (contact)
 * 2016-07-27   B. Leaman   BLL18 Use current user singleton instead of SOQL.
 * 2016-07-29	B. Leaman	BLL19 Add geolocator logic to get lat/lng and county. 
 *							Before logic: clear lat/lng on address change; After logic: Submit future method if lat/lng is null & batch size < 25 (skip mass updates/uploads).
 * 2016-08-17	B. Leaman	BLL20 IT#30131 - Cannot update person city/state/zip without a street address. Correct this logic.
 * 2016-09-20	B. Leaman	BLL21 - New person account wasn't setting the billing address to match person mailing address.
 * 2016-09-21	B. Leaman	BLL22 - Reduce threshhold for running geolocation services and don't run if the user is DealerTeam, because
 *							that's what the Pardot connector runs as, and we don't want to call out whenever Pardot syncs with salesforce.
 * 2016-09-21	B. Leaman	BLL23 - Add New Influencer support.
 * 2016-12-06	B. Leaman	BLL24 - Don't allow account record type changes except by Administrators or between Retail Business & Commercial record types.
 * 2017-04-27	B. Leaman	BLL25 - If a default expense account is specified on a vendor, replace it with our default "DONOTUSE" one, if available.
 * 2018-07-06	B. Leaman	BLL26 - new and improved influencer support; move code to AccountProcess class.
 * 2019-10-08	B. Leaman	W-000764 BLL26 - only run store assignment on insert of a new account.
 * 2019-12-04	B. Leaman	W-000799 BLL28 Count Customer Pay ROs and Rentals and store on account.
 * 2020-01-23	M. Chevalier W-000813 MTC29 Set distance from closest store and assigned store on update on account.
 * 2020-01-28	M. Chevalier MTC30 refactored using TriggerHandler framework
 */
trigger AccountManagement on Account (before insert, before update, before delete, after insert, after update) {
	new AccountTriggerHandler().run();
}