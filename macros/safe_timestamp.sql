{#
  safe_timestamp(microsecond_ts)

  Converts a GA4 event_timestamp (microseconds since Unix epoch) to a proper TIMESTAMP.

  Usage:
    {{ safe_timestamp('event_timestamp') }}
#}

{% macro safe_timestamp(microsecond_ts) %}
  timestamp_micros({{ microsecond_ts }})
{% endmacro %}
