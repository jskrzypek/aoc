(ns webview.example
  (:require ["path" :as path]
            ["vscode" :as vscode]
            ["ext://betterthantomorrow.calva$v0" :as calva]
            [joyride.core :as joyride]
            [promesa.core :as p]
            [z-joylib.editor-utils :as editor-util

(def oc (joyride.core/output-channel))

(defn evaluate-in-session+ [session-key code]
  (p/let [result (calva/repl.evaluateCode
                  session-key
                  code
                  #js {:stdout #(.append oc %)
                       :stderr #(.append oc (str "Error: " %))})]
    (.-result result)))

(defn clj-evaluate+ [code]
  (evaluate-in-session+ "clj" code))


(defn evaluate+
  "Evaluates `code` in whatever the current session is."
  [code]
  (evaluate-in-session+ (calva/repl.currentSessionKey) code))

(defn main []
  (p/let [panel (vscode/window.createWebviewPanel
                 "My webview!" "Scittle"
                 vscode/ViewColumn.Two
                 #js {:enableScripts true})
          html (evaluate+
                "(aocd-utils.tools/download-description *ns* {:ext :html :save false :selector nil})")]
    (set! (.. panel -webview -html) (str html))))

(when (= (joyride/invoked-script) joyride/*file*)
  (main))

;; live demo here: https://twitter.com/borkdude/status/1519607386218053632
