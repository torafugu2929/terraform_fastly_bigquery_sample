# Implement OpenTelemetry in VCL
# ref: https://www.fastly.com/blog/opentelemetry-part-2-using-opentelemetry-in-vcl

sub random_8bit_identifier STRING {
    declare local var.id STRING;
    set var.id = randomstr(16, "0123456789abcdef");
    return var.id;
}
sub random_16bit_identifier STRING {
    declare local var.id STRING;
    set var.id = randomstr(32, "0123456789abcdef");
    return var.id;
}

sub vcl_recv {
    #FASTLY recv
    if (req.restarts == 0) {
        set req.http.x-trace-vcl-span-id = random_8bit_identifier();
        if (req.http.traceparent ~ "^\d+-(\w+)-(\w+)-\d+$") {
            set req.http.x-trace-id = re.group.1;
            set req.http.x-trace-parent-span-id = re.group.2;
        } else {
            set req.http.x-trace-id = random_16bit_identifier();
        }
        set req.http.x-trace-server-role = if (fastly.ff.visits_this_service == 0, "edge", "shield");
    }

    return(lookup);
}

sub vcl_miss {
    #FASTLY miss

    set bereq.http.traceparent = "00-" req.http.x-trace-id + "-" + req.http.x-trace-vcl-span-id "-01";
        
    # Avoid leaking internal headers to backends
    unset bereq.http.x-trace-id;
    unset bereq.http.x-trace-vcl-span-id;
    unset bereq.http.x-trace-parent-span-id;
    unset bereq.http.x-trace-server-role;
    unset bereq.http.Var-cacheLookup;

    # Leapfrog cloud service infra that creates 'ghost spans'
    set bereq.http.x-traceparent = bereq.http.traceparent; 

    return(fetch);
}

sub vcl_pass {
    #FASTLY pass

    set bereq.http.traceparent = "00-" req.http.x-trace-id + "-" + req.http.x-trace-vcl-span-id "-01";
        
    # Avoid leaking internal headers to backends
    unset bereq.http.x-trace-id;
    unset bereq.http.x-trace-vcl-span-id;
    unset bereq.http.x-trace-parent-span-id;
    unset bereq.http.x-trace-server-role;
    unset bereq.http.Var-cacheLookup;

    # Leapfrog cloud service infra that creates 'ghost spans'
    set bereq.http.x-traceparent = bereq.http.traceparent; 

    return(pass);
}

