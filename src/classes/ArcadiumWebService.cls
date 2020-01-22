/**
 *  2015-10-20	B. Leaman	BLL1 - provide sample result when running tests.
 *  2016-03-07  RedTeal     RT1  - Removed sample result. Test should now use WebServiceCalloutMock.
 */
public class ArcadiumWebService {
    public class CreateLeadRecordWithCouponResponse_element {
        public String CreateLeadRecordWithCouponResult;
        private String[] CreateLeadRecordWithCouponResult_type_info = new String[]{'CreateLeadRecordWithCouponResult','http://tempuri.org/',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://tempuri.org/','true','false'};
        private String[] field_order_type_info = new String[]{'CreateLeadRecordWithCouponResult'};
    }
    public class CreateLeadRecordWithCoupon_element {
        public String Source;
        public String FirstName;
        public String LastName;
        public String Address;
        public String City;
        public String State;
        public String ZIP;
        public String Phone;
        public String Email;
        public String detail;
        public Integer response;
        public String stockno;
        public String coupon;
        public String ownedvehicle;
        private String[] Source_type_info = new String[]{'Source','http://tempuri.org/',null,'0','1','false'};
        private String[] FirstName_type_info = new String[]{'FirstName','http://tempuri.org/',null,'0','1','false'};
        private String[] LastName_type_info = new String[]{'LastName','http://tempuri.org/',null,'0','1','false'};
        private String[] Address_type_info = new String[]{'Address','http://tempuri.org/',null,'0','1','false'};
        private String[] City_type_info = new String[]{'City','http://tempuri.org/',null,'0','1','false'};
        private String[] State_type_info = new String[]{'State','http://tempuri.org/',null,'0','1','false'};
        private String[] ZIP_type_info = new String[]{'ZIP','http://tempuri.org/',null,'0','1','false'};
        private String[] Phone_type_info = new String[]{'Phone','http://tempuri.org/',null,'0','1','false'};
        private String[] Email_type_info = new String[]{'Email','http://tempuri.org/',null,'0','1','false'};
        private String[] detail_type_info = new String[]{'detail','http://tempuri.org/',null,'0','1','false'};
        private String[] response_type_info = new String[]{'response','http://tempuri.org/',null,'0','1','false'};
        private String[] stockno_type_info = new String[]{'stockno','http://tempuri.org/',null,'0','1','false'};
        private String[] coupon_type_info = new String[]{'coupon','http://tempuri.org/',null,'0','1','false'};
        private String[] ownedvehicle_type_info = new String[]{'ownedvehicle','http://tempuri.org/',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://tempuri.org/','true','false'};
        private String[] field_order_type_info = new String[]{'Source','FirstName','LastName','Address','City','State','ZIP','Phone','Email','detail','response','stockno','coupon','ownedvehicle'};
    }
    public class MailData {
        public String Name;
        public String Value;
        private String[] Name_type_info = new String[]{'Name','http://tempuri.org/',null,'0','1','false'};
        private String[] Value_type_info = new String[]{'Value','http://tempuri.org/',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://tempuri.org/','true','false'};
        private String[] field_order_type_info = new String[]{'Name','Value'};
    }
    public class MailResponse_element {
        public Integer responseid;
        public String email;
        public ArcadiumWebService.ArrayOfMailData data;
        private String[] responseid_type_info = new String[]{'responseid','http://tempuri.org/',null,'1','1','false'};
        private String[] email_type_info = new String[]{'email','http://tempuri.org/',null,'0','1','false'};
        private String[] data_type_info = new String[]{'data','http://tempuri.org/',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://tempuri.org/','true','false'};
        private String[] field_order_type_info = new String[]{'responseid','email','data'};
    }
    public class CreateLeadRecordResponse_element {
        public String CreateLeadRecordResult;
        private String[] CreateLeadRecordResult_type_info = new String[]{'CreateLeadRecordResult','http://tempuri.org/',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://tempuri.org/','true','false'};
        private String[] field_order_type_info = new String[]{'CreateLeadRecordResult'};
    }
    public class CreateLeadRecord_element {
        public String Source;
        public String FirstName;
        public String LastName;
        public String Address;
        public String City;
        public String State;
        public String ZIP;
        public String Phone;
        public String Email;
        public String detail;
        public Integer response;
        public String stockno;
        private String[] Source_type_info = new String[]{'Source','http://tempuri.org/',null,'0','1','false'};
        private String[] FirstName_type_info = new String[]{'FirstName','http://tempuri.org/',null,'0','1','false'};
        private String[] LastName_type_info = new String[]{'LastName','http://tempuri.org/',null,'0','1','false'};
        private String[] Address_type_info = new String[]{'Address','http://tempuri.org/',null,'0','1','false'};
        private String[] City_type_info = new String[]{'City','http://tempuri.org/',null,'0','1','false'};
        private String[] State_type_info = new String[]{'State','http://tempuri.org/',null,'0','1','false'};
        private String[] ZIP_type_info = new String[]{'ZIP','http://tempuri.org/',null,'0','1','false'};
        private String[] Phone_type_info = new String[]{'Phone','http://tempuri.org/',null,'0','1','false'};
        private String[] Email_type_info = new String[]{'Email','http://tempuri.org/',null,'0','1','false'};
        private String[] detail_type_info = new String[]{'detail','http://tempuri.org/',null,'0','1','false'};
        private String[] response_type_info = new String[]{'response','http://tempuri.org/',null,'0','1','false'};
        private String[] stockno_type_info = new String[]{'stockno','http://tempuri.org/',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://tempuri.org/','true','false'};
        private String[] field_order_type_info = new String[]{'Source','FirstName','LastName','Address','City','State','ZIP','Phone','Email','detail','response','stockno'};
    }
    public class ArrayOfMailData {
        public ArcadiumWebService.MailData[] MailData;
        private String[] MailData_type_info = new String[]{'MailData','http://tempuri.org/',null,'0','-1','true'};
        private String[] apex_schema_type_info = new String[]{'http://tempuri.org/','true','false'};
        private String[] field_order_type_info = new String[]{'MailData'};
    }
    public class MailResponseResponse_element {
        private String[] apex_schema_type_info = new String[]{'http://tempuri.org/','true','false'};
        private String[] field_order_type_info = new String[]{};
    }
    public class Service1Soap {
        public String endpoint_x = 'http://209.190.185.193/MWWebService/MWService.asmx';
        public Map<String,String> inputHttpHeaders_x;
        public Map<String,String> outputHttpHeaders_x;
        public String clientCertName_x;
        public String clientCert_x;
        public String clientCertPasswd_x;
        public Integer timeout_x;
        private String[] ns_map_type_info = new String[]{'http://tempuri.org/', 'ArcadiumWebService'};
        public void MailResponse(Integer responseid,String email,ArcadiumWebService.ArrayOfMailData data) {
            ArcadiumWebService.MailResponse_element request_x = new ArcadiumWebService.MailResponse_element();
            request_x.responseid = responseid;
            request_x.email = email;
            request_x.data = data;
            ArcadiumWebService.MailResponseResponse_element response_x;
            Map<String, ArcadiumWebService.MailResponseResponse_element> response_map_x = new Map<String, ArcadiumWebService.MailResponseResponse_element>();
            response_map_x.put('response_x', response_x);
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{endpoint_x,
              'http://tempuri.org/MailResponse',
              'http://tempuri.org/',
              'MailResponse',
              'http://tempuri.org/',
              'MailResponseResponse',
              'ArcadiumWebService.MailResponseResponse_element'}
            );
            response_x = response_map_x.get('response_x');
        }
        public String CreateLeadRecordWithCoupon(String Source,String FirstName,String LastName,String Address,String City,String State,String ZIP,String Phone,String Email,String detail,Integer response,String stockno,String coupon,String ownedvehicle) {
            ArcadiumWebService.CreateLeadRecordWithCoupon_element request_x = new ArcadiumWebService.CreateLeadRecordWithCoupon_element();
            request_x.Source = Source;
            request_x.FirstName = FirstName;
            request_x.LastName = LastName;
            request_x.Address = Address;
            request_x.City = City;
            request_x.State = State;
            request_x.ZIP = ZIP;
            request_x.Phone = Phone;
            request_x.Email = Email;
            request_x.detail = detail;
            request_x.response = response;
            request_x.stockno = stockno;
            request_x.coupon = coupon;
            request_x.ownedvehicle = ownedvehicle;
            ArcadiumWebService.CreateLeadRecordWithCouponResponse_element response_x;
            Map<String, ArcadiumWebService.CreateLeadRecordWithCouponResponse_element> response_map_x = new Map<String, ArcadiumWebService.CreateLeadRecordWithCouponResponse_element>();
            response_map_x.put('response_x', response_x);
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{endpoint_x,
              'http://tempuri.org/CreateLeadRecordWithCoupon',
              'http://tempuri.org/',
              'CreateLeadRecordWithCoupon',
              'http://tempuri.org/',
              'CreateLeadRecordWithCouponResponse',
              'ArcadiumWebService.CreateLeadRecordWithCouponResponse_element'}
            );
            response_x = response_map_x.get('response_x');
            return response_x.CreateLeadRecordWithCouponResult;
        }
        public String CreateLeadRecord(String Source,String FirstName,String LastName,String Address,String City,String State,String ZIP,String Phone,String Email,String detail,Integer response,String stockno) {
            ArcadiumWebService.CreateLeadRecord_element request_x = new ArcadiumWebService.CreateLeadRecord_element();
            request_x.Source = Source;
            request_x.FirstName = FirstName;
            request_x.LastName = LastName;
            request_x.Address = Address;
            request_x.City = City;
            request_x.State = State;
            request_x.ZIP = ZIP;
            request_x.Phone = Phone;
            request_x.Email = Email;
            request_x.detail = detail;
            request_x.response = response;
            request_x.stockno = stockno;
            ArcadiumWebService.CreateLeadRecordResponse_element response_x;
            Map<String, ArcadiumWebService.CreateLeadRecordResponse_element> response_map_x = new Map<String, ArcadiumWebService.CreateLeadRecordResponse_element>();
            response_map_x.put('response_x', response_x);
            
            //RT1
            /*
            if (Test.isRunningTest()) {  // BLL1a
            	response_x = new ArcadiumWebService.CreateLeadRecordResponse_element();
            	response_x.CreateLeadRecordResult = '{"response_x":"success"}';
	            response_map_x.put('response_x', response_x);
            } else {  // BLL1a
			*/
            //end RT1
            
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{endpoint_x,
              'http://tempuri.org/CreateLeadRecord',
              'http://tempuri.org/',
              'CreateLeadRecord',
              'http://tempuri.org/',
              'CreateLeadRecordResponse',
              'ArcadiumWebService.CreateLeadRecordResponse_element'}
            );
            //}  // BLL1a
            response_x = response_map_x.get('response_x');
            return response_x.CreateLeadRecordResult;
        }
    }
}