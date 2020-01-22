global with sharing class FFPostCreditNote_3 implements rstk.FinancialForce_3.PostCreditNote {
global void postCreditNote(String creditNoteId) {
    c2g.CODAAPICommon.Reference ref = new c2g.CODAAPICommon.Reference();
    ref.Id = creditNoteId;
    c2g.CODAAPISalesCreditNote_7_0.PostCreditNote(null, ref);
}
global void bulkPostCreditNotes(List<String> creditNoteIds) {
    List<c2g.CODAAPICommon.Reference> refs = new List<c2g.CODAAPICommon.Reference>();
   for (String creditNoteId: creditNoteIds) {
      c2g.CODAAPICommon.Reference ref = new c2g.CODAAPICommon.Reference();
      ref.Id = creditNoteId;
      refs.add(ref);
   }    c2g.CODAAPISalesCreditNote_7_0.BulkPostCreditNote(null, refs);
}
}