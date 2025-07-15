package twinspire;

import twinspire.DimObject;
import twinspire.Id;
import twinspire.geom.Dim;
import twinspire.DimIndex;

typedef DimObjectResult = {
    var ?type:Id;
    var ?dim:Dim;
    var ?originalObject:DimObject;
}