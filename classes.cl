(in-package :python)


;; Python metatypes

(defclass python-meta-type (standard-class)
  ())

(defmethod make-instance ((cls (eql (find-class 'python-meta-type))) &rest initargs)
  ;; Create a new Python metatype
  ...)

(defmethod initialize-instance ((cls python-meta-type) &rest initargs)
  ;; Initialize a Python metatype
  ...)

(defmethod slot-value-using-class ((x (eql python-meta-type)) instance slot-name)
  ;; Get attribute of an instance of a Python metatype
  ...)

(defmethod (setf slot-value-using-class)
    (new-value (cls (eql (find-class 'python-meta-type))) instance slot-name)
  ;; Set attribute value of a Python metatype
  ...)

(defmethod slot-boundp-using-class
    ((x (eql (find-class 'python-meta-type))) instance slot-name)
  ;; Does a Python metatype have the attribute?
  ...)

(defmethod slot-makunbound-using-class
    ((x (eql (find-class 'python-meta-type))) instance slot-name)
  ;; Remove attribute of a Python metatype
  ...)


;; Python classes

(defclass python-type (standard-class)
  ((name :initarg :name))
  (:metaclass python-meta-type))

(defmethod make-instance ((cls python-meta-type) &rest initargs)
  ;; Create a new Python class that has CLS as metaclass
  ...)

(defmethod initialize-instance ((cls python-type) &rest initargs)
  ;; Initialize a Python class
  ...)

(defmethod compute-slots ((cls python-type))
  ;; Determine the slots of a Python class
  ...)

(defmethod slot-value-using-class ((cls python-meta-type) instance slot-name)
  ;; Get attribute of a Python class
  ...)

(defmethod (setf slot-value-using-class)
    (new-value (cls python-meta-type) instance slot-name)
  ;; Set atttribute value of a Python class
  ...)

(defmethod slot-boundp-using-class ((x python-meta-type) instance slot-name)
  ;; Does instance have the attribute?
  ...)

(defmethod slot-makunbound-using-class ((x python-meta-type) instance slot-name)
  ;; Remove attribute of a Python class
  ...)


;; Instances of Python classes

(defclass python-object (standard-object)
  ()
  (:metaclass python-type))

(defmethod make-instance ((cls python-type) &rest initargs)
  ;; Create an instance of a Python class.
  ...)

(defmethod initialize-instance ((x python-object) &rest initargs)
  ;; Initialize a Python object (an instance of a Python class)
  ...)

(defmethod slot-value-using-class ((x python-type) instance slot-name)
  ;; Get attribute of an instance of a Python class
  ...)

(defmethod (setf slot-value-using-class)
    (new-value (x python-type) instance slot-name)
  ;; Set atttribute value of an instance of a Python class
  ...)

(defmethod slot-boundp-using-class ((x python-type) instance slot-name)
  ;; Does instance have the attribute?
  ...)

(defmethod slot-makunbound-using-class ((x python-type) instance slot-name)
  ;; Remove attribute of an instance of a Python class
  ...)



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; OLD ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defclass user-defined-class (user-defined-object python-type)
  ((__name__ :initarg :name
	     :type string
	     :documentation "class name")
   (__module__ :initarg :module
	       :type string
	       :documentation "the module this class was defined in")
   (__dict__ :initarg :namespace
	     :documentation "UDC class namespace, containing its methods and class attributes"
	     :initform (make-namespace) ))
  ;; this is NOT the _instance_ dict -- UDCs are *instances* of this class
  (:documentation "Represents all Python classes created within Python (at runtime)."))


;; The reason for having the following class, is that if a UDC Foo
;; defined fixed slots for its instances, then the list of fixed slot
;; names is stored as an attribute in the class Foo itself, namely in
;; the `__slots__' slot.

(defclass user-defined-class-w/slots (user-defined-class)
  ((__slots__ :type list :initarg :slots
	      :documentation "The slots all instances have"))
  (:documentation "Represents all Python classes whose instances have fixed slots."))


;; Python code:
;;   
;;   class Foo:
;;     def meth(self, ..): ..
;; 
;; makes Foo an instance of USER-DEFINED-CLASS, with
;;  `__name__' = "Foo"
;;  `__dict__' = {"meth": <method 'meth'>}

(defclass udc-instance (user-defined-object)
  ()
  (:documentation "Mix-in for UDCs. Idea: all UDC instances are of class UDC-INSTANCE"))

(defclass udc-instance-w/dict (udc-instance)
  ((__dict__ :initarg :dict :initform (make-namespace) ;; was (make-dict) 20041226
	     ))
  (:documentation "Represents all UDC's whose instances have a __dict__."))

(defclass udc-instance-w/slots (udc-instance) ()
  (:metaclass python-type)
  (:documentation "Represents all UDC's whose instances have fixed slots. ~@
                   All UDC instances whose class is of type user-defined-class-w/slots ~@
                   should be of type udc-instance-w/slots."))

(defclass udc-instance-w/dict+slots (udc-instance-w/slots udc-instance-w/dict) ()
	  ;; note: first w/slots, then w/dict - important for attribute lookup methods
  (:metaclass python-type)
  (:documentation "Represents all UDC's whose instances have both some fixed slots and a __dict__."))

  

;; MAKE-PYTHON-CLASS (this documentation needs updating...)
;; 
;; XXX make sure inheritance order is correct when subclassing a buitin class.
;; 
;; XXX Here is an issue: in Python, there can be two classes with the
;; same name, while in CL there can't.
;; 
;; We need to keep track of that at class creation time, by using
;; different Lisp names for every user-defined class, but putting the
;; user-supplied name of it in a slot.
;; 
;; Realize that has-dict and fixed-slots are not mutually exclusive:
;; if __dict__ is explicitly mentioned in the list of slots, this
;; class' instances will have fixed slots, of which __dict__ happens
;; to be one.
;; 
;; To enable fine type dispatching, this is the order in which the
;; superclasses appear in the CPL:
;; 
;;  udc-with-dict udc-with-slots udo
;; 
;; So, if there are slots of which __dict__ is one, we want to treat
;; it as a regular instance with a __dict__, not as a slot-restricted
;; instance.
;; 
;; Defmethods restricted to types udc-with-dict and udc-with-slot will
;; successfully sort out that case.
;; 
;; User-defined-object must come before the builtin-classes (except
;; udo-w-slots and udo-w-dict), so instances of a subclassed built-in
;; class are regarded as UDO first and BIO second, in that order.
;; 
;; XXX maybe class hierarchy can be cleaned up.
;;
;; XXX behaviour different from CPython w.r.t. subclassing slotted
;; classes, and the value of __slots__.

(defun make-python-class (&key name (module "ModuleName")
			       (supers nil) (slots nil) (has-slots nil)
			       (namespace nil) (metaclass nil)
			       (documentation nil))
  (assert (symbolp name))
  (assert (every (lambda (x) (typep x 'class)) supers))
  
  (when (eq metaclass (find-class 'python-type))
    (setf metaclass nil))
  
  (cond (metaclass (warn "make-u-d-class with given metaclass: ~A" metaclass)
		   (assert (typep metaclass 'class))
		   #+(or)(unless (subtypep metaclass 'python-type)
			   (py-raise 'TypeError
				     "Metaclass for class ~A is ~A, which is not a subtype of `type'."
				     name (class-name metaclass)))
		   (when has-slots
		     #+(or)(warn "Class ~A has __metaclass__ specified. Therefore, the value for ~@
                            __slots__ is ignored (value of __slots__: ~A)"
			   name (call-attribute-via-class slots '__repr__)))
		   (return-from make-python-class
		     (make-u-d-class-with-given-metaclass name metaclass
							  :namespace namespace
							  :module module
							  :supers supers)))
	
	
	((some (lambda (cls) (subtypep cls 'python-type))
	       supers)
	 (return-from make-python-class
	   (make-u-d-class-derived-from-type name supers :namespace namespace :module module))))
  
  
  ;; All classes that are accessible from within Python
  ;; inherit from python-object, so throw it away when it is
  ;; explicitly mentioned.
  ;; 
  ;; TODO: this hides some circularity errors in CPL.
  
  (setf supers
    (loop for s in supers
	do (assert (typep s 'class))
	unless (eq s (find-class 'python-object))
	collect s))

  ;; Determine the slots the instances of this class are supposed to have.
  ;; 
  ;; This happens in multiple steps, as the logic is a bit tricky.
  ;; 
  ;; First step: analyze the class options supplied. If no explicit
  ;; `slots' specified, give instances a __dict__ for all attributes.
  ;; 
  ;; If __slots__ is...      then effectively...
  ;;  ()                 ->   slots=[],     (no dict) -- effectively no attribs at all
  ;;  ('__dict__')       ->   slots=['__dict__']      -- same as if slots were not specified
  ;;  ('__dict__', 'a')  ->   slots=['__dict__', 'a'] -- allocate `a' in special slot, rest in dict
  ;;  ('a')              ->   slots=['a']   (no dict) -- only allow `a', which has its own slot
  ;;  <absent>           ->   slots=['__dict__']      -- everything in dict

  (let* ((inst-have-dict (or (not has-slots)
			     (and has-slots (member '__dict__ slots))))
	 (the-other-slots (loop
			      with lst = slots
			      for s in '(__dict__ __slots__ __name__)
			      do (setf lst (remove s lst :test 'eq))
			      finally (return lst)))
	 (inst-have-other-slots the-other-slots)
	 
	 (supers-cls supers)) ;; XXX clean up

    ;; Determine the appropriate mix-in class. This can't be more
    ;; restricted than any of the UDC superclasses.
    ;;  
    ;;  udc-instance               -- no dict, no slots, nothing
    ;;  udc-instance-w/dict        -- just a dict, no other fixed slots
    ;;  udc-instance-w/slots       -- no dict, but some other slots
    ;;  udc-instance-w/dict+slots  -- both a dict and other slots

    (loop for cls in supers-cls
	if (subtypep cls 'udc-instance-w/dict)
	do (setf inst-have-dict t)
	if (subtypep cls 'udc-instance-w/slots)
	do (setf inst-have-other-slots t))
    
    (let ((the-mixin (cond ((and inst-have-other-slots inst-have-dict) 'udc-instance-w/dict+slots)
			   (inst-have-dict 'udc-instance-w/dict)
			   (inst-have-other-slots 'udc-instance-w/slots)
			   (t 'udc-instance)))
	  
	  (the-metaclass (progn (assert (not metaclass)) ;; no __metaclas__ given by user
				(if inst-have-other-slots 
				    'user-defined-class-w/slots
				  'user-defined-class))))
	     
      ;; Now determine the superclasses. 
      ;; 
      ;; The order of superclasses is:
      ;;  1) all classes mentioned in SUPERS
      ;;  2) the UDC-* mixin (determined above)
      ;;  3) if there are built-in classes in SUPERS: BIO.
      ;; 
      ;; We always want BIO af the end, so that when built-in classes
      ;; are subclassed, a method specialized on UDC-I takes
      ;; precedence above one specialized on BIO.
      ;; 
      ;; Here are some examples of the resulting class precedence
      ;; lists:
      ;; 
      ;;                CPL (after Foo)           meta
      ;;  ------------------------------------------------------------
      ;;  Foo           udc-i-w/d                 udc
      ;;  Foo(Sup)      Sup, udc-i-w/d            udc
      ;;  Foo(int)      udc-i-w/d, int, bio       udc <- note: bio at the end, after udc-*
      ;;  Foo(Bar,int)  Bar, udc-i-w/d, int, bio  udc
      ;;  Foo(int,Bar)  int, Bar, udc-i-w/d, bio  udc <- note: bio at the end, after udc-*
      ;;
      ;; udo = user-defined-object
      ;; udc = user-defined-class
      ;; udc/slots = user-defined-class-w/slots
      ;; bio  = built-in-object
      ;; udc-i-w/d = udc-instance-w/dict
      ;; 
      ;; [ When class has list of slots, meta becomes udc/slots, and in
      ;; [ CPL replace udc-i-w/d with udc-i-w/s.
      ;; [ When class has both slots and dict, meta also becomes
      ;; [ udc/slots, in CPL replace udc-i-w/d with udc-i-w/d+s.

      (let* ((has-a-builtin-super (some (lambda (c) (typep c 'builtin-class))
					supers-cls))
	     (the-supers `(,@supers ,the-mixin ,@(when has-a-builtin-super
						   '(builtin-instance builtin-object))))
	     
	     (dummy #+(or)(warn "Creating ~A: supers = ~A  meta = ~A" name the-supers the-metaclass))
	     
	     ;; Finally, create the class
	     (k (mop:ensure-class
		 name
		 :direct-superclasses the-supers
		 :metaclass the-metaclass
		 :documentation documentation
		 :direct-slots
		 `( ,@(mapcar
		       (lambda (slot-name)
			 (if (eq slot-name '__dict__)
			     `(:name ,slot-name :iniform '(make-namespace))
			   `(:name ,slot-name)))
		       the-other-slots) ))))
	(declare (ignore dummy))
	
	(mop:finalize-inheritance k) ;; Not sure if this is needed?

	;; Some bookkeeping
	
	(let ((namespace
	       (or namespace
		   (make-namespace
		    :name (format nil "ns for class ~A, created by default"
				  (string name))))))

	  (setf (slot-value k '__name__) (string name)
		(slot-value k '__module__) module
		(slot-value k '__dict__) namespace)
	  
	  (when the-other-slots
	    (setf (slot-value k '__slots__) the-other-slots))
	  
	  k)))))

(defclass udc-derived-from-type ()
  ())
(mop:finalize-inheritance (find-class 'udc-derived-from-type))

(defmethod make-u-d-class-derived-from-type ((name symbol) (supers list)
					     &key module namespace)
  (let* ((real-supers (remove (find-class 'user-defined-class)
			      (remove (find-class 'python-type)
				      supers)))
	 (klass (mop:ensure-class
		 name
		 :direct-superclasses `(,@real-supers
					user-defined-class
					udc-derived-from-type)
		 :metaclass 'user-defined-class)))
    (mop:finalize-inheritance klass)
    (setf (slot-value klass '__dict__) namespace
	  (slot-value klass '__name__) (symbol-name name)
	  (slot-value klass '__module__) module)
    klass))

(defmethod make-u-d-class-with-given-metaclass
    ((name symbol) (metaclass class) &key supers module namespace)
  (let ((klass
	 (mop:ensure-class
	  name
	  :direct-superclasses `(,@(remove (find-class 'python-object) supers)
				   #+(or)user-defined-class
				   udc-instance-w/dict python-object) ;; udc?
	  :metaclass #+(or)metaclass
	  (metaclass-for-udc-with-ud-metaclass metaclass)
	  :direct-slots '((:name __dict__)))))
    (mop:finalize-inheritance klass)
    (setf (slot-value klass '__dict__) namespace
	  (slot-value klass '__name__) name
	  (slot-value klass '__module__) module)
    klass)) ;; XXX user-defined-object mixin?


(defclass udc-with-ud-metaclass (#+(or)user-defined-class udc-instance-w/dict)
  ()) ;; metatype?

(mop:finalize-inheritance (find-class 'udc-with-ud-metaclass))
		  

(defmethod metaclass-for-udc-with-ud-metaclass ((mc class))
  (let* ((name (intern
		(format nil "udc-ud-mc+~A" (class-name mc)) #.*package*))
	 (k (mop:ensure-class
	     name
	     :direct-superclasses (list mc 'udc-with-ud-metaclass 
					#+(or)'standard-class))))
    (mop:finalize-inheritance k)
    k))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; New design of user-defined classes

(defclass py-udc ()
  ((name :initarg :name)
   (metaclass :initarg :metaclass :initform nil)
   (baseclasses :initarg :baseclasses :initform nil)
   (subclasses :initarg :subclasses :initform nil)
   (slots :initarg :slots :initform nil)
   (has-slots :initarg :has-slots)
   (namespace :initarg :namespace)
   (mro :initarg :mro)
   (subtype-of-type :initarg :subtype-of-type :initform nil)))

(defclass py-udc-inst ()
  ((class :initarg :class)
   (attributes))) ;; alist


(defun make-udc (&rest args)
  (apply #'make-instance (find-class 'py-udc) args))

(defmethod make-udc-inst ((cls py-udc))
  (make-instance cls))
