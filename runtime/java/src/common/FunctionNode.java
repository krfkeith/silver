package common;

/**
 * FunctionNode is a Node, but with a doReturn method.
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

	// TODO: we should make doReturn an interface, perhaps?
	public Object doReturn() {
		
		if(getSynthesized(0) == null) {
			throw new RuntimeException("Function " + getName() + " has no return value!");
		}
		
		try {
			return getSynthesized(0).eval(this.decorate());
		} catch(Throwable t) {
			throw new RuntimeException("Error while evaluating function " + getName(), t);
		}
	}

	@Override
	public final Lazy getForward() {
		throw new RuntimeException("Functions do not forward!");
	}

	@Override
	public final Lazy getForwardInh(final int index) {
		throw new RuntimeException("Functions do not forward!");
	}

	@Override
	public final int getNumberOfInhAttrs() {
		return 0;
	}

	@Override
	public final int getNumberOfSynAttrs() {
		return 1;
	}

	@Override
	public final String getNameOfInhAttr(final int index) {
		throw new RuntimeException("Functions do not possess inherited attributes! (Requested name of index " + index + ")");
	}

	@Override
	public final String getNameOfSynAttr(final int index) {
		switch(index) {
		case 0:
			return "__return_value__"; // Should this be something else, perhaps?
		default:
			throw new RuntimeException("Functions do not possess synthesized attributes beyond their return value. (Requested name of index " + index + ")");
		}
	}
	
}
