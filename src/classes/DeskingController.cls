/**
 * WMK, LLC (c) - 2018 
 *
 * DeskingController
 * 
 * Created By:   Alexander Miller
 * Created Date: 12/14/2018
 * Tested By:    DeskingControllerTest
 * Work Item:    W-000472
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 *
 */
global class DeskingController { 
    
    public static List<dealer__Vehicle_Inventory__c> listOfVehicles {get;set;}
    
    public static List<String> listOfVehicleImages {get;set;}
    
    public static String listOfVehiclesJSON {get;set;}

    public static dealer__Dealer_Location__c homeLocation {get;set;}

    public static Double distanceGlobal {get;set;}

    public static Double mileageGlobal {get;set;}

    public static List<locationDistance> listOfInRangeLocations {get;set;} 

    public static String reloadVehicleListingString {get;set;}
     
    public DeskingController()
    {
        // disable during dev
        setHomeLocation();

        listOfInRangeLocations = getStoresInDistance(75);
        
        listOfVehicles = getVehicleListing(listOfInRangeLocations);

        listOfVehicleImages = getVehicleImages(listOfVehicles);

        listOfVehiclesJSON = JSON.serialize(listOfVehicles);

        System.debug(listOfVehiclesJSON);
    }

    public static void setHomeLocation()
    {
        // List<dealer__Dealer_Location__c> tempLocationhomeLocation = ([SELECT Id, 
        //                                                                 Name, 
        //                                                                 Sales_Admin__c, 
        //                                                                 Commercial_Sales_Admin__c, 
        //                                                                 Rental_Manager__c,
        //                                                                 dealer__Physical_Location__Latitude__s, 
        //                                                                 dealer__Physical_Location__Longitude__s 
        //                                                             FROM dealer__Dealer_Location__c
        //                                                             WHERE Regional_Service_Manager__c = :userInfo.getUserId() OR 
        //                                                                 Sales_Admin__c = :userInfo.getUserId() OR 
        //                                                                 Commercial_Sales_Admin__c = :userInfo.getUserId() OR 
        //                                                                 Rental_Manager__c = :userInfo.getUserId()]);

        homeLocation = [SELECT Id, 
                                Name, 
                                Sales_Admin__c, 
                                Commercial_Sales_Admin__c, 
                                Rental_Manager__c,
                                dealer__Physical_Location__Latitude__s, 
                                dealer__Physical_Location__Longitude__s
                           FROM dealer__Dealer_Location__c
                           WHERE Name = 'Akron'
                           LIMIT 1];

        // if(tempLocationhomeLocation.size() > 0)
        // {
        //     homeLocation = tempLocationhomeLocation.get(0);
        // }

        System.debug(homeLocation);
    }

    /**
    * getStoresInDistance
    *
    * Function which returns a list of Stores based on the current home store
    * of the logged in user.
    *
    *   @param distanceParam - number of miles to evaluate locations against
    * 
    *   @return List<dealer__Dealer_Location__c> - listOfLocations found to be within the number of miles presented by distanceParam
    */
    public static List<locationDistance> getStoresInDistance(Double distanceParam)
    {
        // Filters applied to exclude places like BDC, East, West, TransitWorks, etc
        List<dealer__Dealer_Location__c> listOfLocations = ([SELECT Id, 
                                                                Name, 
                                                                dealer__Physical_Location__Latitude__s, 
                                                                dealer__Physical_Location__Longitude__s 
                                                            FROM dealer__Dealer_Location__c
                                                            WHERE Sales_Admin__c != null AND
                                                                dealer__Service_Director__c != null]);

        List<locationDistance> listOfReturningLocations = new List<locationDistance>();
        
        setHomeLocation();

        if(homeLocation != null)
        {
            Location loc1 = Location.newInstance(homeLocation.dealer__Physical_Location__Latitude__s, homeLocation.dealer__Physical_Location__Longitude__s);

            for(dealer__Dealer_Location__c tempLocation : listOfLocations)
            {
                Location loc2 = Location.newInstance(tempLocation.dealer__Physical_Location__Latitude__s, tempLocation.dealer__Physical_Location__Longitude__s);

                Double dist = Location.getDistance(loc1, loc2, 'mi');

                if(dist < distanceParam)
                {
                    listOfReturningLocations.add(new locationDistance(tempLocation, dist));
                }
            }
        }

        listOfReturningLocations.sort();

        return listOfReturningLocations;
    }

    /**
    *
    *
    *
    *
    *
    */
    public static List<dealer__Vehicle_Inventory__c> getVehicleListing(List<locationDistance> listOfLocations)
    {
        List<dealer__Dealer_Location__c> listOfLocs = new List<dealer__Dealer_Location__c>();

        for(locationDistance tempLoc : listOfLocations)
        {
            listOfLocs.add(tempLoc.location);
        }

        System.debug(mileageGlobal);

        if(mileageGlobal == null)
        {
            mileageGlobal = 1000000;
        }

        return ([SELECT Id,
                           dealer__Year__c,
                           dealer__Make__c,
                           dealer__Model__c,
                           dealer__Trim_Level__c,
                           dealer__Transmission_Type__c,
                           dealer__Exterior_Color__c,
                           dealer__Interior_Color__c,
                           dealer__Mileage__c,
                           dealer__Store_Location__c,
                           dealer__Stock_Number__c,
                           dealer__Store_Location__r.Name,
                           	(SELECT Id,
                              	dealer__Vehicle_Inventory__c,
                              	dealer__CDNThumbnailURL__c,
                              	dealer__Sequence_Number__c,
                              	dealer__Image_URL__c
                              FROM dealer__Inventory_Images__r
                              WHERE dealer__Sequence_Number__c = 0)
                           FROM dealer__Vehicle_Inventory__c 
                           WHERE Id IN (SELECT dealer__Vehicle_Inventory__c
                                        FROM dealer__Inventory_Images__c) AND
                                dealer__Store_Location__c IN :listOfLocs AND
                                dealer__Status_Code__c != 'Not For Sale' AND
                                dealer__Status_Code__c != 'Demo - Not for Sale' AND
                                dealer__Status_Code__c != 'Order - Sold Not Delivered' AND
                                dealer__Status_Code__c != 'Sold - Not Delivered' AND
                                dealer__Status_Code__c != 'Rental' AND
                                dealer__Status_Code__c != 'Rental - Not for Sale' AND
                                dealer__Mileage__c < :mileageGlobal
                            LIMIT 10]);
    }

    public static List<String> getVehicleImages(List<dealer__Vehicle_Inventory__c> listOfVehicles)
    {
        List<String> returningList = new List<String>();

        for(dealer__Vehicle_Inventory__c temp : listOfVehicles)
        {
            for(dealer__Inventory_Images__c tempImage : temp.dealer__Inventory_Images__r)
            {                
                returningList.add(tempImage.dealer__Image_URL__c);
            }
		}

        return returningList;
    }

    @RemoteAction 
    global static void invokeLocationDistanceFunction()
    {   
        listOfInRangeLocations = getStoresInDistance(distanceGlobal);

        listOfVehicles = getVehicleListing(listOfInRangeLocations);

        listOfVehicleImages = getVehicleImages(listOfVehicles);

        listOfVehiclesJSON = JSON.serialize(listOfVehicles);
    }

    /**
    * locationDistance
    *
    * Object to record the runtime distance 
    * from the home store so it can be displayed
    * cleanly
    *
    */
    public class locationDistance implements Comparable
    {
        public dealer__Dealer_Location__c location {get;set;}

        public Double distance {get;set;}

        public locationDistance(){}

        public locationDistance(dealer__Dealer_Location__c loc, Double dist)
        {
            this.location = loc;
            this.distance = dist;
        }

        public Integer compareTo(Object c1) {
            locationDistance compareTo = (locationDistance) c1;

            if(distance > compareTo.getDistance())
            {
                return 1;
            }
            else if(distance == compareTo.getDistance())
            {
                return 0;
            }
            else 
            {
               return -1;
            }
        }

        public Double getDistance()
        {
            return this.distance;
        }
    }
}