{#
  extract_event_param(event_params, param_key, value_type)

  Extracts a value from the GA4 event_params repeated RECORD field.
  
  Args:
    event_params: The event_params column (repeated RECORD)
    param_key: The key name to extract (e.g., 'page_location')
    value_type: One of 'string', 'int', 'float', 'double' (default: 'string')
  
  Usage:
    {{ extract_event_param('event_params', 'page_location', 'string') }}
#}

{% macro extract_event_param(event_params, param_key, value_type='string') %}
  {%- if value_type == 'int' -%}
    (select value.int_value from unnest({{ event_params }}) where key = '{{ param_key }}' limit 1)
  {%- elif value_type == 'float' -%}
    (select value.float_value from unnest({{ event_params }}) where key = '{{ param_key }}' limit 1)
  {%- elif value_type == 'double' -%}
    (select value.double_value from unnest({{ event_params }}) where key = '{{ param_key }}' limit 1)
  {%- else -%}
    (select value.string_value from unnest({{ event_params }}) where key = '{{ param_key }}' limit 1)
  {%- endif -%}
{% endmacro %}
