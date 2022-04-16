create or replace package sifen_utils as

    function calcular_dv (
        p_numero varchar2,
        p_basemax in number default 11
    ) return number;

    function generar_cdc (
        p_tipo_documento number,
        p_ruc varchar2,
        p_establecimiento varchar2,
        p_punto_expedicion varchar2,
        p_numero_documento varchar2,
        p_tipo_contribuyente number,
        p_tipo_emision number,
        p_fecha_emision date default sysdate
    ) return varchar2;

end;

/

create or replace package body sifen_utils as

    -- funciones privadas


    -- funciones públicas del paquete

    function calcular_dv (
        p_numero varchar2,
        p_basemax in number default 11
    ) return number is
        v_numero varchar2(64);
        k number;
        v_accum number;
        v_ntmp number;
    begin
        v_numero := p_numero;
        -- si el documento termina en letra, transformarlo para el cálculo
        if ascii(substr(v_numero, -1)) not between ascii('0') and ascii('9') then
            v_numero := substr(v_numero, 1, length(v_numero) -1) || ascii(upper(substr(v_numero, -1)));
        end if;

        k := 2;
        v_accum := 0;

        for i in reverse 1 .. length(v_numero) loop
            if k > p_basemax then
                k := 2;
            end if;

            v_ntmp := to_number(substr(v_numero, i, 1));
            v_accum := v_accum + (v_ntmp * k);
            k := k + 1;
        end loop;

        if mod(v_accum, p_basemax) > 1 then
            return p_basemax - mod(v_accum, p_basemax);
        else
            return 0;
        end if;
    end calcular_dv;

    function generar_cdc (
        p_tipo_documento number,
        p_ruc varchar2,
        p_establecimiento varchar2,
        p_punto_expedicion varchar2,
        p_numero_documento varchar2,
        p_tipo_contribuyente number,
        p_tipo_emision number,
        p_fecha_emision date default sysdate
    ) return varchar2 is
        v_cdc varchar2(64);
    begin
        v_cdc :=
           lpad(p_tipo_documento, 2, '0')
        || lpad(p_ruc, 8, '0')
        || sifen_utils.calcular_dv(p_ruc)
        || lpad(p_establecimiento, 3, '0')
        || lpad(p_punto_expedicion, 3, '0')
        || lpad(p_numero_documento, 7, '0')
        || p_tipo_contribuyente
        || to_char(p_fecha_emision, 'yyyymmdd')
        || p_tipo_emision
        || lpad(dbms_random.value(0, 999999999), 9, '0')
        ;
        return v_cdc || sifen_utils.calcular_dv(v_cdc);
    end generar_cdc;

end;

/
