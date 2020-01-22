/**
 * AvaTaxRequestMock
 * Used by AvaTax_MBW_TEST
 * 
 * Usage:
 * AvaTaxRequestMock mock = new AvaTaxRequestMock(200, 'Complete', '<soap:...>');
 */
@isTest
public class AvaTaxRequestMock implements WebServiceMock {

	public void doInvoke(Object stub, Object request, Map<String,Object> response, String endpoint, 
		String soapAction, String requestName, String responseNS, String responseName, String responseType) {
		System.debug('soapAction='+soapAction+', requestName='+requestName);
		if (requestName=='GetTax') {
			TaxSvc.GetTaxResponse_element responseElement = new TaxSvc.GetTaxResponse_element();
			responseElement.GetTaxResult = new TaxSvc.GetTaxResult(); 
			responseElement.GetTaxResult.ResultCode = 'Success';
			responseElement.GetTaxResult.TotalTax = 1.00;
			response.put('response_x', responseElement);
		}
		if (requestName=='PostTax') {
			TaxSvc.PostTaxResponse_element responseElement = new TaxSvc.PostTaxResponse_element();
			responseElement.PostTaxResult = new TaxSvc.PostTaxResult(); 
			responseElement.PostTaxResult.ResultCode = 'Success';
			response.put('response_x', responseElement);
		}
		if (requestName=='CancelTax') {
			TaxSvc.CancelTaxResponse_element responseElement = new TaxSvc.CancelTaxResponse_element();
			responseElement.CancelTaxResult = new TaxSvc.CancelTaxResult(); 
			responseElement.CancelTaxResult.ResultCode = 'Success';
			response.put('response_x', responseElement);
		}
		if (requestName=='CommitTax') {
			TaxSvc.CommitTaxResponse_element responseElement = new TaxSvc.CommitTaxResponse_element();
			responseElement.CommitTaxResult = new TaxSvc.CommitTaxResult(); 
			responseElement.CommitTaxResult.ResultCode = 'Success';
			response.put('response_x', responseElement);
		}
		if (requestName=='AdjustTax') {
			TaxSvc.AdjustTaxResponse_element responseElement = new TaxSvc.AdjustTaxResponse_element();
			responseElement.AdjustTaxResult = new TaxSvc.AdjustTaxResult(); 
			responseElement.AdjustTaxResult.ResultCode = 'Success';
			response.put('response_x', responseElement);
		}
		if (requestName=='GetTaxHistory') {
			TaxSvc.GetTaxHistoryResponse_element responseElement = new TaxSvc.GetTaxHistoryResponse_element();
			responseElement.GetTaxHistoryResult = new TaxSvc.GetTaxHistoryResult(); 
			responseElement.GetTaxHistoryResult.ResultCode = 'Success';
			response.put('response_x', responseElement);
		}
		if (requestName=='IsAuthorized') {
			TaxSvc.IsAuthorizedResponse_element responseElement = new TaxSvc.IsAuthorizedResponse_element();
			responseElement.IsAuthorizedResult = new TaxSvc.IsAuthorizedResult(); 
			responseElement.IsAuthorizedResult.ResultCode = 'Success';
			response.put('response_x', responseElement);
		}
		if (requestName=='Ping') {
			TaxSvc.PingResponse_element responseElement = new TaxSvc.PingResponse_element();
			responseElement.PingResult = new TaxSvc.PingResult(); 
			responseElement.PingResult.ResultCode = 'Success';
			response.put('response_x', responseElement);
		}
		if (requestName=='ApplyPayment') {
			TaxSvc.ApplyPaymentResponse_element responseElement = new TaxSvc.ApplyPaymentResponse_element();
			responseElement.ApplyPaymentResult = new TaxSvc.ApplyPaymentResult();
			response.put('response_x', responseElement);
		}
		if (requestName=='ReconcileTaxHistory') {
			TaxSvc.ReconcileTaxHistoryResponse_element responseElement = new TaxSvc.ReconcileTaxHistoryResponse_element();
			responseElement.ReconcileTaxHistoryResult = new TaxSvc.ReconcileTaxHistoryResult(); 
			responseElement.ReconcileTaxHistoryResult.ResultCode = 'Success';
			response.put('response_x', responseElement);
		}
		
	}
	
}