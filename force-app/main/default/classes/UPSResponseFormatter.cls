public class UPSResponseFormatter {
        Map<String, Object> responseStatusMap;

        public UPSResponseFormatter(Map<String, Object> upsResponse) {
            Map<String, Object> responseObjectMap = (Map<String, Object>) upsResponse.get('Response');
            this.responseStatusMap = (Map<String, Object>) responseObjectMap.get('ResponseStatus');
        }

        public String getUPSResponseCode() {
            return (String) this.responseStatusMap.get('Code');
        }
    }