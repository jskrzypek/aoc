(ns debug)


(def ENABLED
  (atom false))

(def debug?
  "Check if the form has a :debug meta set."
  (comp :debug meta))

;; (defmacro debugf
;;   [format & body]
;;   (list 'do
;;         (conj body 'printf fmt)
;;         (cons format body)))

(defmacro debug
  ([form] `(do (when-let [opts (debug? ~form)] (debug ~form opts)) form))
  ([form
    {::keys [printer args]
     :as opts
     :or {printer  println
          args [%]}}]
   (prn form opts printer passthru prform)
   (cond->> (list 'do)
     prform (conj (list printer form opts))
    ;;  prval  (conj (list printer (form) opts))
     passthru   (conj form)
     true #(do (prn %) %))))

(defmacro ->debug
  ([form] (->debug {:debug 'println} form))
  ([{debug :debug :as opts} form]
   (with-meta 
     (list 'do (list (condp debug debug) form) form)
     opts)))

;; (defmacro dbgn
;;   [body]
;;   (when-not (seq? body)
;;     (list 'prn body))
;;   body)


(defmacro when-enabled
  [form]
  
  (list 'when ENABLED (debug form)))

(defmacro dobug
  "Like when but checks the -debug atom"
  ([-debug & body]
   (into
    (list 'do '(println body))
    (for [form body]
      (if (debug? form)
        
        form)))))

(defmacro defnbug
  "Like defn but checks the -debug atom"
  ([name args body]
   `(debugfn (list 'deref -debug) ~name ~args ~body))
  ([-debug name args body]
   `(def ~name (fn ~args (cons 'debug ~-debug ~body)))))

(defmacro debug->
  [x & forms]
  (loop [x x, forms forms]
    (if forms
      (let [form (first forms)
            threaded (with-meta
                       (if (seq? form)
                         `(~(first form) ~x ~@(next form))
                         (list form x))
                       (meta form))]
        (if (debug? threaded)
          (recur (list 'do (list 'when ENABLED (println threaded)) form) (next forms))
          (recur threaded (next forms))))
      x)))

(defmacro debug->>
  [x & forms]
  (loop [x x, forms forms]
    (if forms
      (let [form (first forms)
            threaded (with-meta
                       (if (seq? form)
                         `(~(first form) ~@(next form) ~x)
                         (list form x))
                       (meta form))]
        (if (debug? threaded)
          (recur (list 'do (list 'when ENABLED (println threaded)) form) (next forms))
          (recur threaded (next forms))))
      x)))

(comment
  (reset! -debug true)
  (reset! -debug false)
  (dobug -debug (^:debug (println "This is debug")
                 (+ 2 2)))
  (dobug (deref -debug)
         ^:debug (println "This is debug")
         (debugln "hello!")
         ^:debug (reset! -debug false)
         (debugln "still here!")
         (reset! -debug false)
         (debugln "not me :(")
         (reset! -debug true)
         ^:debug (println :goodbye)
         (+ 2 2))
  ())