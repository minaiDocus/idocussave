<?php
/*
© 2008 - Michel Petit <petit.michel@gmail.com>

Ceci est un logiciel libre. Vous pouvez en distribuer des copies sous les
termes de la GNU General Public License <http://www.gnu.org/licenses/gpl.html>.
Il n'y a AUCUNE GARANTIE, dans les limites autorisées par la loi.
*/


/**
 * @file Properties.class.php
 * @author Michel Petit aka Malenki (petit.michel@gmail.com)
 */

/**
 * @brief Exploite les fichiers *.properties à la 
 * sauce Java.
 */

class Properties {
  private $file          = null;
  private $keyValue      = array();
  private $newLine       = "\n";
  private $separator     = '=';
  private $withMultiline = false; 
  private $os = PHP_OS;

  /**
   * @brief Le constructeur.
   * @param $file Le nom du fichier à lire
   */
  public function __construct($file){
    if(file_exists($file) and !is_dir($file)){
      $this->file = $file;
    }
  }

  /**
   * @brief Indique quel est le retour à la ligne utilisé
   * @param $newLine @c String indiquant le retour 
   * ("\r","\r\n" ou "\n")
   * @see setNewLineAsDOS(), setNewLineAsUNIX() et 
   * setNewLineAsMAC()
   */
  private function setNewLine($newLine){
    $this->newLine = $newLine;
  }

  /**
   * @brief Indique qu'il faut utiliser et prendre en compte 
   * les retours à la
   * ligne de type DOS/Windows
   */
  public function setNewLineAsDOS(){
    $this->setNewLine("\r\n");
  }

  /**
   * @brief Indique qu'il faut utiliser et prendre en compte 
   * les retours à la
   * ligne de type UNIX
   */
  public function setNewLineAsUNIX(){
    $this->setNewLine("\n");
  }

  /**
   * @brief Indique qu'il faut utiliser et prendre en compte 
   * les retours à la
   * ligne de type MAC
   */
  public function setNewLineAsMAC(){
    $this->setNewLine("\r");
  }

  /**

   * @brief Indique qu'il faut utiliser et prendre en compte 
   * les retours à la
   * ligne de selon le systeme d'exploitation
   */
  public function setNewLineAsOS(){
	$operatingSystem =  $this->os ;
	$operatingSystem = strtolower($operatingSystem);
	
	if (preg_match("/lin/", $operatingSystem)){
	    $this->setNewLine("\n");
	}
	else if (preg_match("/darwin/", $operatingSystem)){
	      $this->setNewLine("\n");
	}
	else if (preg_match("/win/", $operatingSystem)){
	     $this->setNewLine("\r\n");
	}
	else {
	   print "ERROR : OPERATING SYSTEM NOT SUPPORTED ";
	   print "ERROR : YOU MUST SPECIFY YOUR OPEARATING SYSTEM VARIABLE ";
	   exit(1);
	} 
 }	

  /**
   * @brief Utilisation de valeurs ayant des retours à la 
   * ligne en leur sein
   */
  public function useMultilineValues(){
    $this->withMultiline = true;
  }

  /**
   * @brief Utilisation de valeurs sans retour à la ligne
   *
   * Si un retour à la ligne se présente, le reste de la 
   * valeur après le premier
   * retour à la ligne est ignoré.
   */
  public function useOneLineValues(){
    $this->withMultiline = false;
  }

  /**
   * @brief Parcourt le fichier et stocke les valeurs trouvées
   * @return Boolean
   */
  public function readContent(){
    if(!is_null($this->file)){
      $content = file_get_contents($this->file);
      $content = explode($this->newLine,$content);

      // On parcourt le tableau qui contient les lignes...
      foreach($content as $line){
        // Si on trouve un signe "égal", alors on s'attend à trouver 2 parties
        if(strpos($line,$this->separator) !== false){
          list($key,$value) = explode($this->separator,$line);
          $key   = trim($key);
          $value = trim($value);

          // On vérifie que la clé est non nulle, si nulle, est ignorée
          if(strlen($key) > 0)
            $this->keyValue[$key] = $value;

          // On stocke la dernière clé pour le cas des retours à la ligne dans
          // les valeurs (cf. en-dessous)
          $lastKey = $key;
        } else {
          if($this->withMultiline){
            // On est dans le cas où il n'y a pas de signe "égal"
            $line = trim($line);

            // Si la ligne contient quelquechose, et qu'au moins une clé est déjà
            // stockée, alors on concataine cette ligne à la valeur de la clé
            // précédente
            if(strlen($line) > 0 and count($this->keyValue) > 0){
              $this->keyValue[$lastKey] .= $this->newLine.$line;
            }
          }
        }
      }

      return true;
    } else {
      return false;
    }
  }

  /**
   * @brief Écrit les valeurs dans le fichier.
   */
  public function writeContent(){
    if(!is_null($this->file)){
      $str = '';

      foreach($this->keyValue as $k => $v){
        $str .= $k . $this->separator . $v . $this->newLine;
      }

      $result = file_put_contents($this->file, $str);

      if($result === false)
        return false;

      return true;
    } else {
      return false;
    }
  }

  /**
   * @brief Retourne les valeurs trouvées
   *
   * Les valeurs trouvées sont retournées sous la forme d'un 
   * tableau. S'il n'y a aucune valeur, retourne @c null
   *
   * @return mixed
   */
  public function getAllValues(){
    if(count($this->keyValue) == 0)
      return null;
    return $this->keyValue;
  }

  /**
   * @brief Retourne une valeur donnée.
   *
   * Si le tableau est vide ou que la clé n'existe pas, 
   * retourne @c false.
   */
  public function getValue($key){
    if(!array_key_exists($key,$this->keyValue) or count($this->keyValue) == 0)
      return false;
    return $this->keyValue[$key];
  }

  /**
   * @brief Fournit une valeur à une clé.
   *
   * @param $key Nom de la clé
   * @param $value Valeur de la clé
   */
  public function setValue($key, $value){
    $this->keyValue[$key] = $value;
    return true;
  }

}
?>
