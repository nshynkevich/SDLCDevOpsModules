
package kubernetes.validating.label
import future.keywords.contains
import future.keywords.in

has_key(x, k) { _ = x[k] }
contains_elem(a, elem) {
  a[_] = elem
}


operations := {"CREATE", "UPDATE", "DELETE"}

user_namespaces := {
    "shark": {
        "allow": ["default", "kube-system"],
        "disallow": []
     },
    "pewpew": {
        "allow": ["pewpew-ns"],
        "disallow": ["default", "kube-system"]
    }
    
}

deny [msg] {
    input.request.operation in operations

    username := input.request.userInfo.username
    namespace := input.request.object.metadata.namespace
    
    has_key(user_namespaces, username)
    

    kd := "disallow"
    ka := "allow"
    
    contains_elem(user_namespaces[username][kd], namespace)
    not contains_elem(user_namespaces[username][ka], namespace)
    
    
    msg := sprintf("Unauthorized: %v is not permitted to modify objects in namespace %v", [username, namespace])
}
