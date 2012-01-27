/**
 * Copyright(c) 2011
 *
 * Licensed under the terms of the Open Source LGPL 3.0
 * http://www.gnu.org/licenses/lgpl.html
 *     
 */

Ext.util.Format.comboRenderer = function(combo){
    return function(value){
        var record = combo.findRecord(combo.valueField, value);
        return record ? record.get(combo.displayField) : combo.valueNotFoundText;
    }
}



Ext.util.Format.Currency = function(v){
    v = Ext.num(String(v).replace(/\,/, '.'));
    v = (Math.round((v-0)*100))/100;
    v = (v == Math.floor(v)) ? v + ".00" : ((v*10 == Math.floor(v*10)) ? v + "0" : v);
    if (v==0)
    {
        v = '-';
        return (v);
    }
    else
    {
        return (v + ' &euro;').replace(/\./, ',');
    }
};


