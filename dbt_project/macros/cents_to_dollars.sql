-- macros/cents_to_dollars.sql
-- Reusable macro to cast a numeric column and round to 2 decimal places.
-- The Olist dataset stores prices in BRL (not cents), but this macro
-- standardizes rounding and casting across all models.
--
-- Usage: {{ cents_to_dollars('price') }}
-- Output: ROUND(CAST(price AS DOUBLE), 2)

{% macro cents_to_dollars(column_name) %}
    round(cast({{ column_name }} as double), 2)
{% endmacro %}
