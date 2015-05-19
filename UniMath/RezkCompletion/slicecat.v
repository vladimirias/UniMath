(** Definition of slice categories C/X and proof that if C is a
    category then C/X is also a category *)
Require Import Foundations.Generalities.uu0.
Require Import Foundations.hlevel1.hProp.
Require Import Foundations.hlevel2.hSet.

Require Import RezkCompletion.precategories.

Local Notation "a --> b" := (precategory_morphisms a b) (at level 50, left associativity).
Local Notation "f ;; g"  := (compose f g) (at level 50, format "f  ;;  g").

(* Slice category:

Given a category C and x : obj C. The slice category C/x is given by:

- obj C/x: pairs (a,f) where f : a -> x

- morphism (a,f) -> (b,g): morphism h : a -> b with

           h
       a - - -> b
       |       /
       |     /
     f |   / g
       | /
       v
       x

    where h ;; g = f

*)
Section slice_precat_def.

Variable C : precategory.
Variable x : C.

Definition slicecat_ob := total2 (fun (a : C) => a --> x).
Definition slicecat_mor (f g : slicecat_ob) :=
  total2 (fun h : pr1 f --> pr1 g => h ;; pr2 g = pr2 f).

Definition slice_precat_ob_mor : precategory_ob_mor :=
  tpair _ _ slicecat_mor.

Definition id_slice_precat (c : slice_precat_ob_mor) : c --> c :=
  tpair _ _ (id_left _ _ _ (pr2 c)).

Definition comp_slice_precat' (a b c : slice_precat_ob_mor)
  (f : a --> b) (g : b --> c) : (pr1 f ;; pr1 g) ;; pr2 c = pr2 a.
Proof.
rewrite <- assoc, (pr2 g).
exact (pr2 f).
Qed.

Definition comp_slice_precat (a b c : slice_precat_ob_mor)
                             (f : a --> b) (g : b --> c) : a --> c :=
  tpair _ (pr1 f ;; pr1 g) (comp_slice_precat' a b c f g).

Definition slice_precat_data : precategory_data :=
  precategory_data_pair _ id_slice_precat comp_slice_precat.

Lemma is_precategory_slice_precat_data (hsC : has_homsets C) :
  is_precategory slice_precat_data.
Proof.
repeat split; simpl.
* intros a b f.
  case f; clear f; intros h hP.
  apply total2_paths2_second_isaprop; [ apply id_left | apply hsC ].
* intros a b f.
  case f; clear f; intros h hP.
  apply total2_paths2_second_isaprop; [ apply id_right | apply hsC ].
* intros a b c d f g h.
  apply total2_paths2_second_isaprop; [ apply assoc | apply hsC ].
Qed.

Definition slice_precat (hsC : has_homsets C) : precategory :=
  tpair _ _ (is_precategory_slice_precat_data hsC).

End slice_precat_def.

Section slice_precat_theory.

Variable C : precategory.
Variable hsC : has_homsets C.
Variable x : C.

Local Notation "C / X" := (slice_precat C X hsC).

Lemma has_homsets_slice_precat : has_homsets (C / x).
Proof.
intros a b.
case a; clear a; intros a f; case b; clear b; intros b g; simpl.
apply (isofhleveltotal2 2); [ apply hsC | intro h].
apply isasetaprop; apply hsC.
Qed.

Lemma eq_mor_slicecat (af bg : C / x) (f g : af --> bg) : pr1 f = pr1 g -> f = g.
Proof. intro heq; apply (total2_paths heq); apply hsC. Qed.

Lemma eq_iso_slicecat (af bg : C / x) (f g : iso af bg) : pr1 f = pr1 g -> f = g.
Proof.
case g; case f; clear f g; simpl; intros f fP g gP eq.
apply (total2_paths2_second_isaprop eq); apply isaprop_is_iso.
Qed.

(* It suffices that the underlying morphism is an iso to get an iso in
   the slice category *)
Lemma iso_to_slice_precat_iso (af bg : C / x) (h : af --> bg)
  (isoh : is_iso (pr1 h)) : is_iso h.
Proof.
case (is_z_iso_from_is_iso _ isoh).
intros hinv hinvP; case hinvP; clear hinvP; intros h1 h2.
assert (pinv : hinv ;; pr2 af = pr2 bg).
  rewrite <- id_left, <- h2, <- assoc, (pr2 h).
  apply idpath.
apply is_iso_from_is_z_iso.
exists (tpair _ hinv pinv).
split; apply total2_paths2_second_isaprop; trivial; apply hsC.
Qed.

(* An iso in the slice category gives an iso in the base category *)
Lemma slice_precat_iso_to_iso  (af bg : C / x) (h : af --> bg)
  (p : is_iso h) : is_iso (pr1 h).
Proof.
case (is_z_iso_from_is_iso _ p); intros hinv hinvP.
case hinvP; clear hinvP; intros h1 h2.
apply is_iso_from_is_z_iso.
exists (pr1 hinv); split.
  apply (maponpaths pr1 h1).
apply (maponpaths pr1 h2).
Qed.

Lemma iso_weq (af bg : C / x) :
  weq (iso af bg) (total2 (fun h : iso (pr1 af) (pr1 bg) => h ;; pr2 bg = pr2 af)).
Proof.
apply (weqcomp (weqtotal2asstor _ _)).
apply invweq.
apply (weqcomp (weqtotal2asstor _ _)).
apply weqfibtototal; intro h; simpl.
apply (weqcomp (weqdirprodcomm _ _)).
apply weqfibtototal; intro p.
apply weqimplimpl; try apply isaprop_is_iso.
  intro hp; apply iso_to_slice_precat_iso; assumption.
intro hp; apply (slice_precat_iso_to_iso _ _ _ hp).
Defined.

End slice_precat_theory.

Section slicecat_theory.

Variable C : precategory.
Variable is_catC : is_category C.
Variable x : C.

Local Notation "C / x" := (slice_precat C x (pr2 is_catC)).

Lemma id_weq_iso_slicecat (af bg : C / x) : weq (af = bg) (iso af bg).
Proof.
set (a := pr1 af); set (f := pr2 af); set (b := pr1 bg); set (g := pr2 bg).

assert (weq1 : weq (af = bg)
                   (total2 (fun (p : a = b) => transportf _ p (pr2 af) = g))).
  apply (total2_paths_equiv _ af bg).

assert (weq2 : weq (total2 (fun (p : a = b) => transportf _ p (pr2 af) = g))
                   (total2 (fun (p : a = b) => idtoiso (! p) ;; f = g))).
  apply weqfibtototal; intro p.
  rewrite idtoiso_precompose.
  apply idweq.

assert (weq3 : weq (total2 (fun (p : a = b) => idtoiso (! p) ;; f = g))
                   (total2 (fun h : iso a b => h ;; g = f))).
  apply (weqbandf (weqpair _ ((pr1 is_catC) a b))); intro p.
  rewrite idtoiso_inv; simpl.
  apply weqimplimpl; simpl; try apply (pr2 is_catC); intro Hp.
    rewrite <- Hp, assoc, iso_inv_after_iso, id_left; apply idpath.
  rewrite <- Hp, assoc, iso_after_iso_inv, id_left; apply idpath.

assert (weq4 : weq (total2 (fun h : iso a b => h ;; g = f)) (iso af bg)).
  apply invweq; apply iso_weq.

apply (weqcomp weq1 (weqcomp weq2 (weqcomp weq3 weq4))).
Defined.

Lemma is_category_slicecat : is_category (C / x).
Proof.
split; [| apply has_homsets_slice_precat]; simpl; intros a b.
set (h := id_weq_iso_slicecat a b).
apply (isweqhomot h); [intro p|case h; trivial].
destruct p.
apply eq_iso.
apply eq_mor_slicecat; trivial.
Qed.

End slicecat_theory.