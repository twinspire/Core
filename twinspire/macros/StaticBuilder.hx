package twinspire.macros;
#if macro

import haxe.macro.Context;
import haxe.macro.Expr;

/**
A macro-based static field builder designed to make all fields in a class marked `static` with the intention of coding procedurally instead of object-oriented.
**/
class StaticBuilder
{

    public static macro function build():Array<Field>
    {
        var fields = Context.getBuildFields();
        var isPublic = true;
        for (field in fields)
        {
            if (field.meta != null)
            {
                for (m in field.meta)
                {
                    if (m.name == ":global")
                    {
                        isPublic = true;
                    }
                    else if (m.name == ":local")
                    {
                        isPublic = false;
                    }
                }
            }

            if (isPublic)
                field.access = [AStatic, APublic];
            else 
                field.access = [AStatic];
        }

        return fields;
    }

}

#end