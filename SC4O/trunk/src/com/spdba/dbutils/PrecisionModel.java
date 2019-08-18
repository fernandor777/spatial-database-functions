package com.spdba.dbutils;

import org.locationtech.jts.geom.Coordinate;

public class PrecisionModel extends org.locationtech.jts.geom.PrecisionModel {
    public PrecisionModel(org.locationtech.jts.geom.PrecisionModel precisionModel) {
        super(precisionModel);
    }

    public PrecisionModel(double d) {
        super(d);
    }

    public PrecisionModel(org.locationtech.jts.geom.PrecisionModel.Type type) {
        super(type);
    }

    public PrecisionModel() {
        super();
    }
    
    @Override
    public void makePrecise(Coordinate coord)
    {
      // optimization for full precision
      if (super.getType() == FLOATING) return;

        coord.setX(makePrecise(coord.getX()));
        coord.setY(makePrecise(coord.getY()));
        coord.setZ(makePrecise(coord.getZ()));
    }
}
