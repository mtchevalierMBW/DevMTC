public class JSON2Apex {

	public class Options {
		public String optionId;
		public String questionId;
		public String value;
		public Boolean selected;
	}

	public String questionId;
	public String campaignId;
	public String accountId;
	public List<Options> options;

	public static List<JSON2Apex> parse(String json) {
		return (List<JSON2Apex>) System.JSON.deserialize(json, List<JSON2Apex>.class);
	}
}