package stirling.software.SPDF.config.security.session;

// import java.util.ArrayList;
// import java.util.List;

// import org.springframework.beans.factory.annotation.Autowired;
// import org.springframework.web.bind.annotation.GetMapping;
// import org.springframework.web.bind.annotation.RestController;

// import jakarta.servlet.http.HttpServletRequest;
// import jakarta.servlet.http.HttpSession;
// import lombok.extern.slf4j.Slf4j;
// import stirling.software.SPDF.model.SessionEntity;

// @RestController
// @Slf4j
public class SessionController {

    // // @Autowired private SessionPersistentRegistry sessionRegistry;

    // @GetMapping("/active-sessions")
    // public List<String> getActiveSessions() {
    //     List<String> activeUsers = new ArrayList<>();
    //     // for (SessionEntity se : sessionRegistry.getAllSessionsNotExpired()) {
    //     //     log.info(se.getPrincipalName() + " " + se.isExpired());
    //     //     activeUsers.add(se.getPrincipalName());
    //     // }
    //     // log.info(activeUsers.size() + " activeUsers");
    //     return activeUsers;
    // }

    // @GetMapping("/session-timeout")
    // public String getSessionTimeout(HttpServletRequest request) {
    //     HttpSession session = request.getSession(false);
    //     if (session != null) {
    //         int timeout = session.getMaxInactiveInterval();
    //         return "Current session timeout is: " + timeout + " seconds";
    //     } else {
    //         return "No active session found.";
    //     }
    // }
}
