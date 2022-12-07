(ns
 y2022.d7
 (:require
  [aoc-util.tools
   :refer
   [create-next-day
    download-description
    download-examples
    get!
    open-browser
    submit-first!
    submit-second!]]
  [aoc-util.utils :refer [parse-int line-process] :as utils]
  [clojure.string :as str]
  [clojure.walk]
  [wing.core :as w]))

(defn command
  [^String s]
  (let [[f cmd & dir] (str/split s #" ")]
    (when (= f "$")
      {:cmd cmd :dir (first dir)})))

(defn file
  [^String s]
  (let [[size name] (str/split s #" " 2)]
    (when (not= (first size) \$)
      (if (= size "dir")
        {:name name :type :dir}
        {:name name :type :file :size (Integer/parseInt size)}))))

(defn conforms?
  ([pred]
   (partial conforms? pred))
  ([pred x & {conform-kvs :conform-kvs}]
   (cond
     ;; conform key-value preds (or 2-vecs if conform-kvs is false)
     (every? (every-pred vector? #(= 2 (count %))) [pred x]) 
     (let [[pk pv] pred
           [k v] x]
       (if conform-kvs
         (or (not (conforms? pk k)) (conforms? pv v))
         (and (conforms? pk k) (conforms? pv v))))

     ;; associative maps of preds
     (every? associative? [pred x])
     (every?
      (apply
       every-pred
       (map (fn [p] #(conforms? p % {:conform-kvs (map? pred)})) pred))
      x)

     ;; other generic preds, shorthand equality 
     :else (if (fn? pred) (pred x) (= pred x)))))

(def updir {:cmd "cd" :dir ".."})
(def updir? (conforms? updir))
(def downdir {:cmd "cd" :dir (partial not= "..")})
(def downdir? (conforms? downdir))

(defn parse-output
  [output]
  (->> output
       (partition-by (complement command))
       (partition-all 2)
      ;;  (#(doall (map prn %) %))
       (map (fn [[cmds files]] (list (map command cmds) (map file files))))))

(def input (parse-output (get!)))
(comment 
  (get!)
  (parse-output (get!))
  input)

(defn do-cd
  [path {dir :dir :as cmd}]
  (condp conforms? cmd
    updir   (drop-last path)
    downdir (conj path dir)
    path))

(defn resolve-cwd
  "Execute the command and then return the path"
  [path [cmd & cmds]]
  (cond-> path
    (not (vector? path)) vec
    (not (nil? cmd))     (do-cd cmd)
    (not-empty cmds)     (resolve-cwd cmds)))

(comment 
  input
  (associative? updir)
  (conforms? [int? string?] [3 "5"])
  (updir? {:cmd "cd" :dir ".."})
  (updir? {:cmd "ls" :dir ".."})
  (updir? {:cmd "ls" :dir nil})
  (updir? {:cmd "cd" :dir "foo"})
  (downdir? {:cmd "cd" :dir ".."})
  (downdir? {:cmd "cd" :dir "foo"})
  (downdir? {:cmd "ls" :dir "foo"})
  (downdir? {:cmd "ls" :dir nil})
  )

#_(defn resolve-cwd
  [path [cmd & cmds]]
  (int)
  (loop [path path
         cmds cmds]
    (if (not-empty cmds)
      (recur (cmd->pwd path (first cmds))
             (rest cmds))
      (into [] path)))
  (let [updirs (filter updir? cmds)
        downdirs (filter downdir? cmds)]
    (into []
          (concat (drop-last (count updirs) path)
                  (mapv :dir downdirs)))))

(def tree-node?
  (conforms?
   {:size int?}))

(def dir?
  (conforms? {:type :dir}))

(def file?
  (conforms? {:type :file :size int?}))

(defn file-sizes
  [files]
  (->> files
       (filter file?)
       (map :size)
       (reduce +)))

(defn tree-seq-adding-parent
  "Like tree-seq, but takes in a tree of maps and a unique :parent key to each map."
  [branch? children root]
  (let [walk (fn walk [parent node]
               (lazy-seq
                (cons (assoc node :parent parent)
                      (when (branch? node)
                        (mapcat (partial walk node) (children node))))))]
    (walk nil root)))

(defn string-key-vals
  [m]
  (->> m
       keys
       (filter string?)
       (select-keys m)
       vals))

(defn child-dirs
  [node]
  (->> node
       :files
       (filter dir?)
       (map :name)
       (select-keys node)
       vals))

(defn recursive-size
  [{:keys [size] :as node} & _]
  (->> node
       child-dirs
       (map recursive-size)
       (reduce + size)))



(defn calculate-sizes
  [node]
  (if (and (map? node) (tree-node? node))
    (assoc node
           :fsize (:size node)
           :size (reduce + (:size node) (map :size (child-dirs node))))
    node))

(defn walkulate-sizes
  [tree]
  (clojure.walk/postwalk calculate-sizes tree))

(defn make-tree
  [output]
  (loop [path         []
         tree         {}
         [[cmds files] & output] output]
    (let [path (resolve-cwd path cmds)]
      (if (every? empty? [cmds files output])
        (get tree "/")
        (recur path
               (-> tree
                   (assoc-in (conj path :size)
                             (file-sizes files))
                   (assoc-in (conj path :files)
                             files)
                   (assoc-in (conj path :path)
                             (str/join "/" path)))
               (seq output))))))

(defn size-under
  [parsed-output max-size]
  (->> (make-tree parsed-output)
       walkulate-sizes
       (tree-seq associative? child-dirs)
       (#(do (prn (map (juxt :path :size) %)) %))
       (filter (comp (partial >= max-size) :size))
       (map :size)
      ;;  (filter (partial >= max-size))
       (reduce +)))

#_(defn file-tree-seq
  [output]
  (->> output
       make-tree
       (tree-seq )))

(comment
  (file-sizes nil)
  (resolve-cwd ["/" "a"] nil)
  (resolve-cwd ["/" "a"] (map command '("$ cd c" "$ cd b" "$ ls" "$ cd .." "$ cd d")))
  input
  (resolve-cwd ["/" "a"] (map command '("$ cd c" "$ cd b" "$ ls" "$ cd .." "$ cd d")))
  (file-sizes ["dir e"
               "29116 f"
               "2557 g"
               "62596 h.lst"])
  (file-sizes
   (into
    []
    (flatten (for [[_ files] input] files))))
  (make-tree input)
  
  (def example
    (parse-output
     ["$ cd /"
      "$ ls"
      "dir a"
      "14848514 b.txt"
      "8504156 c.dat"
      "dir d"
      "$ cd a"
      "$ ls"
      "dir e"
      "29116 f"
      "2557 g"
      "62596 h.lst"
      "$ cd e"
      "$ ls"
      "584 i"
      "$ cd .."
      "$ cd .."
      "$ cd d"
      "$ ls"
      "4060174 j"
      "8033020 d.log"
      "5626152 d.ext"
      "7214296 k"]))
  example
  (child-dirs (make-tree example))
  ()
  (size-under example 100000)
  (size-under input 100000)
  ()
  (->> (file-tree-seq)  keys)
  (spit "tree.edn" (prn-str (make-tree)))
  (download-description)
  (download-examples)
  (submit-first! (size-under input 100000))
  (->> (make-tree input)
       (tree-seq associative? child-dirs)
       (map :size)
       (filter (partial <= 100000))
       (reduce +))
  
  (->> (make-tree input)
       (clojure.walk/postwalk ))
  (->> (make-tree)
       (tree-seq associative? child-dirs)
       (filter (comp string? :path))
       (filter #(<= (:size %) 100000))
      ;;  (filter #(<= (recursive-size %) 100000))
      ;;  (map recursive-size)
       #_(reduce +))
  (recursive-size {:size 0
                   :path "//nhqwt/mcnjwwfr/dqp/rpchqq/lrphzrv/tln/vnjfrhp/dqp/dcqnblb"
                   "zprprf"
                   {:size 261548
                    :path "//nhqwt/mcnjwwfr/dqp/rpchqq/lrphzrv/tln/vnjfrhp/dqp/dcqnblb/zprprf"
                    "bqnpsl" {:size 188232, :path "//nhqwt/mcnjwwfr/dqp/rpchqq/lrphzrv/tln/vnjfrhp/dqp/dcqnblb/zprprf/bqnpsl"}
                    "dszrvpzc" {:size 0, :path "//nhqwt/mcnjwwfr/dqp/rpchqq/lrphzrv/tln/vnjfrhp/dqp/dcqnblb/zprprf/dszrvpzc"}}})
  )

(comment
  (download-description)
  (submit-second!)
  )


(comment (create-next-day))

