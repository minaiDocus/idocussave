<?php
/*
� 2008 - Michel Petit <petit.michel@gmail.com>

Ceci est un logiciel libre. Vous pouvez en distribuer des copies sous les
termes de la GNU General Public License <http://www.gnu.org/licenses/gpl.html>.
Il n'y a AUCUNE GARANTIE, dans les limites autoris�es par la loi.
*/


/**
 * @file Properties.class.php
 * @author Michel Petit aka Malenki (petit.michel@gmail.com)
 */

/**
 * @brief Exploite les fichiers *.properties � la 
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
   * @param $file Le nom du fichier � lire
   */
  public function __construct($file){
    if(file_exists($file) and !is_dir($file)){
      $this->file = $file;
    }
  }

  /**
   * @brief Indique quel est le retour � la ligne utilis�
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
   * les retours � la
   * ligne de type DOS/Windows
   */
  public function setNewLineAsDOS(){
    $this->setNewLine("\r\n");
  }

  /**
   * @brief Indique qu'il faut utiliser et prendre en compte 
   * les retours � la
   * ligne de type UNIX
   */
  public function setNewLineAsUNIX(){
    $this->setNewLine("\n");
  }

  /**
   * @brief Indique qu'il faut utiliser et prendre en compte 
   * les retours � la
   * ligne de type MAC
   */
  public function setNewLineAsMAC(){
    $this->setNewLine("\r");
  }

  /**

   * @brief Indique qu'il faut utiliser et prendre en compte 
   * les retours � la
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
   * @brief Utilisation de valeurs ayant des retours � la 
   * ligne en leur sein
   */
  public function useMultilineValues(){
    $this->withMultiline = true;
  }

  /**
   * @brief Utilisation de valeurs sans retour � la ligne
   *
   * Si un retour � la ligne se pr�sente, le reste de la 
   * valeur apr�s le premier
   * retour � la ligne est ignor�.
   */
  public function useOneLineValues(){
    $this->withMultiline = false;
  }

  /**
   * @brief Parcourt le fichier et stocke les valeurs trouv�es
   * @return Boolean
   */
  public function readContent(){
    if(!is_null($this->file)){
      $content = file_get_contents($this->file);
      $content = explode($this->newLine,$content);

      // On parcourt le tableau qui contient les lignes...
      foreach($content as $line){
        // Si on trouve un signe "�gal", alors on s'attend � trouver 2 parties
        if(strpos($line,$this->separator) !== false){
          list($key,$value) = explode($this->separator,$line);
          $key   = trim($key);
          $value = trim($value);

          // On v�rifie que la cl� est non nulle, si nulle, est ignor�e
          if(strlen($key) > 0)
            $this->keyValue[$key] = $value;

          // On stocke la derni�re cl� pour le cas des retours � la ligne dans
          // les valeurs (cf. en-dessous)
          $lastKey = $key;
        } else {
          if($this->withMultiline){
            // On est dans le cas o� il n'y a pas de signe "�gal"
            $line = trim($line);

            // Si la ligne contient quelquechose, et qu'au moins une cl� est d�j�
            // stock�e, alors on concataine cette ligne � la valeur de la cl�
            // pr�c�dente
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
   * @brief �crit les valeurs dans le fichier.
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
   * @brief Retourne les valeurs trouv�es
   *
   * Les valeurs trouv�es sont retourn�es sous la forme d'un 
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
   * @brief Retourne une valeur donn�e.
   *
   * Si le tableau est vide ou que la cl� n'existe pas, 
   * retourne @c false.
   */
  public function getValue($key){
    if(!array_key_exists($key,$this->keyValue) or count($this->keyValue) == 0)
      return false;
    return $this->keyValue[$key];
  }

  /**
   * @brief Fournit une valeur � une cl�.
   *
   * @param $key Nom de la cl�
   * @param $value Valeur de la cl�
   */
  public function setValue($key, $value){
    $this->keyValue[$key] = $value;
    return true;
  }

}
?>
