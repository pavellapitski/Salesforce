/**
 * Created by Pavel Lapitski on 2020-05-08.
 */

global abstract class InvoiceWebServiceResponse {

    /*
    200	OK
    201	CREATED
    202	ACCEPTED
    204	NO_CONTENT
    206	PARTIAL_CONTENT
    300	MULTIPLE_CHOICES
    301	MOVED_PERMANENTLY
    302	FOUND
    304	NOT_MODIFIED
    400	BAD_REQUEST
    401	UNAUTHORIZED
    403	FORBIDDEN
    404	NOT_FOUND
    405	METHOD_NOT_ALLOWED
    406	NOT_ACCEPTABLE
    409	CONFLICT
    410	GONE
    412	PRECONDITION_FAILED
    413	REQUEST_ENTITY_TOO_LARGE
    414	REQUEST_URI_TOO_LARGE
    415	UNSUPPORTED_MEDIA_TYPE
    417	EXPECTATION_FAILED
    500	INTERNAL_SERVER_ERROR
    503	SERVER_UNAVAILABLE
    */

    public static final Integer OK = 200;
    public static final Integer INTERNAL_SERVER_ERROR = 500;

    public enum Statuses { SUCCESS, ERROR }

    public String status { get; set; }
    public String message { get; set; }

    public virtual void success(Integer statusCode, System.RestResponse res) {
        this.status = Statuses.SUCCESS.name();
        res.statusCode = statusCode;
    }

    public virtual void error(Integer statusCode, System.RestResponse res, String errorMessage) {
        this.status = Statuses.ERROR.name();
        this.message = errorMessage;
        res.statusCode = statusCode;
    }

}