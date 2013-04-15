/*
 * Variables used:
 *   PKG_NAME
 *   LANG_NAME
 */
package silver.composed.idetest.imp.builders;

import java.io.File;
import java.util.List;
import java.util.Set;
import java.util.Map.Entry;

import org.eclipse.core.runtime.IProgressMonitor;
import org.eclipse.core.resources.IProject;

import ide.NIdeMessage;
import ide.NIdeProperty;
import ide.PmakeIdeProperty;
import silver.composed.idetest.SILVERService;

import edu.umn.cs.melt.ide.silver.property.ProjectProperties;
import edu.umn.cs.melt.ide.silver.property.Property;
import edu.umn.cs.melt.ide.silver.env.SilverEnv;
import edu.umn.cs.melt.ide.silver.misc.ConsoleLoggingStream;

/**
 * A helper class used to invoke the method build(NIdeProperty[]) in the language 
 * implementation jar.
 * <p>
 * Used for all-in-one plugin.
 */
public class SILVERBuildInvoker {
	
	private static SILVERBuildInvoker invoker;
	
	public static SILVERBuildInvoker getInstance(){
		if(invoker==null){
			invoker = new SILVERBuildInvoker();
		}
		
		common.Util.environment.put("SILVER_HOME", SilverEnv.getSilverHome().getAbsolutePath());
		common.Util.environment.put("SILVER_GEN", SilverEnv.getGeneratedFolder().getAbsolutePath());
		
		return invoker;
	}
	
	/**
	 * 
	 * @param project
	 * @param clstream		
	 * @param monitor
	 * @param handler
	 * @return
	 */
	public boolean build(
		IProject project, 
		ConsoleLoggingStream clstream, 
		IProgressMonitor monitor,
		PostActionHandler handler) {

		//Get properties
		ProjectProperties properties = SILVERService.getInstance().getProperties(project);

		try {
			//Extract properties			
			NIdeProperty[] args = SILVERService.convertToNIdePropertyList(properties);
			
			List<NIdeMessage> list = silver.composed.idetest.Build.build(args);
			return handler.handleBuild(list);
		} catch (Exception t) {
			t.printStackTrace();
			clstream.error("BUILD FAILED: failed to invoke builder of SILVER.)");
			return false;
		}
		
	}

}

