package common;

import common.exceptions.MissingDefinitionException;
import common.exceptions.SilverInternalError;
import common.exceptions.TraceException;

/**
 * FunctionNode is a Node, but with a few methods "removed".
 * 
 * We do things ever so slightly backwards. Instead of making production a subtype of function,
 * we make function a subtype of production.  Thus, here we wall off a few production-only things
 * that don't apply to functions (and throw exceptions if they are requested.)
 * 
 * @author tedinski
 * @see Node
 */
public abstract class FunctionNode extends Node {

	protected FunctionNode(final Object[] children) {
		super(children);
	}

	@Override
	public final Node getForward(final DecoratedNode context) {
		throw new SilverInternalError("Functions do not forward!");
	}

	@Override
	public final Lazy getForwardInheritedAttributes(final int index) {
		throw new SilverInternalError("Functions do not forward!");
	}

	@Override
	public final Lazy getSynthesized(final int index) {
		throw new SilverInternalError("Functions do not possess synthesized attributes! (Requested index " + index + ")");
	}

	@Override
	public final int getNumberOfInhAttrs() {
		return 0;
	}

	@Override
	public final int getNumberOfSynAttrs() {
		return 0;
	}

	@Override
	public final String getNameOfInhAttr(final int index) {
		throw new SilverInternalError("Functions do not possess inherited attributes! (Requested name of index " + index + ")");
	}

	@Override
	public final String getNameOfSynAttr(final int index) {
		throw new SilverInternalError("Functions do not possess synthesized attributes! (Requested name of index " + index + ")");
	}
	
}
